import re

from kubernetes import client
from kubernetes import config

import py2yaml


label_blacklist = ['pod-template-hash', 'release_group',
                   'controller-uid', 'controller-revision-hash',
                   'pod-template-generation', 'app',
                   'statefulset.kubernetes.io/pod-name',
                   ]


def get_k8s_client():
    try:
        config.load_incluster_config()
    except config.config_exception.ConfigException:
        config.load_kube_config()
    return client


def get_all_deployment():
    k8s = get_k8s_client()
    return k8s.AppsV1Api().list_deployment_for_all_namespaces().items


def build_get_cmd(namespace, label, resource='po'):
    return (f'kubectl -n {namespace} get {resource} -l "{label}" -owide')


def build_delete_cmd(namespace, label, resource='po'):
    return (f'kubectl -n {namespace} delete {resource} -l "{label}"')


def build_describe_cmd(namespace, label, index,
                       resource='po'):
    return (f'kubectl describe po -n {namespace} '
            f'$(kubectl -n {namespace} get {resource} -l "{label}" '
            f'--no-headers -o jsonpath="{{.items[{index}].metadata.name}}")')


def build_logs_cmd(namespace, label, container=None, host=False):
    cmd = (f'for p in $(kubectl -n {namespace} get po -owide -l "{label}"'
           f' --no-headers -o custom-columns=":metadata.name" ')
    if host:
        cmd += "--field-selector spec.nodeName=$host "
    cmd += f");do kubectl -n {namespace} logs "
    if container:
        cmd += f"-c {container} "
    cmd += "$p;done"
    return cmd


def build_tail_cmd(namespace, label, container=None, index=None, host=False):
    cmd = (f'kubectl -n {namespace} logs '
           f'$(kubectl -n {namespace} get po -owide -l "{label}" '
           f'--no-headers -o jsonpath="{{.items[{index}].metadata.name}}" ')
    if host:
        cmd += "--field-selector spec.nodeName=$host "
    cmd += ") -f --tail 20"
    if container:
        cmd += f" -c {container}"
    return cmd


def build_exec_cmd(namespace, label, index=None, container=None, host=False):
    cmd = (f'kubectl exec -it -n {namespace} '
           f'$(kubectl -n {namespace} get po -owide -l "{label}" ')
    if index is not None:
        cmd += f'--no-headers -o jsonpath="{{.items[{index}].metadata.name}}" '
    if host:
        cmd += "--field-selector spec.nodeName=$host "
    cmd += ") "
    if container:
        cmd += f"-c {container} "
    cmd += "-- bash"
    return cmd


def build_scale_cmd(namespace, deployment):
    return (f"kubectl -n {namespace} scale deployment "
            f"{deployment} --replicas=")


def generate_commands():
    commands = {}
    k8s = get_k8s_client()
    pods = k8s.CoreV1Api().list_pod_for_all_namespaces().items
    for po in pods:
        labels = po.metadata.labels
        for k in label_blacklist:
            labels.pop(k, None)
        selector = ",".join([f"{k}={v}" for k, v in labels.items()])
        # remove random suffix of pod name
        ower = po.metadata.owner_references[0]
        pod_name = po.metadata.name
        if ower and ower.kind in ('Job',):
            continue
        if ower and ower.kind in ('ReplicaSet',):
            pod_name = '_'.join(pod_name.split('-')[:-2])
        if ower and ower.kind in ('StatefulSet', 'DaemonSet'):
            pod_name = '_'.join(pod_name.split('-')[:-1])

        pattern = r'node_[a-z0-9]+'
        pod_name = re.sub(pattern, '', pod_name)
        pod_name = pod_name.replace(f'{po.metadata.namespace}_', '')

        commands[f'get_{pod_name}'] = build_get_cmd(
            po.metadata.namespace, selector)
        commands[f'delete_{pod_name}'] = build_delete_cmd(
            po.metadata.namespace, selector)

        containers = [c.name for c in po.spec.containers]
        for c in containers:
            commands[f'logs_{pod_name}_{c}'] = build_logs_cmd(
                po.metadata.namespace, selector, container=c)
            commands[f'tail_{pod_name}_{c}'] = build_tail_cmd(
                po.metadata.namespace, selector, container=c, index="$A")
            commands[f'exec_{pod_name}_{c}'] = build_exec_cmd(
                po.metadata.namespace, selector, container=c, index="$A")
    # save to file
    py2yaml.save_yaml(commands, 'k8s.yaml')


if __name__ == '__main__':
    generate_commands()
