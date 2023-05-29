import yaml


class quoted(str):
    pass


def quoted_presenter(dumper, data):
    return dumper.represent_scalar('tag:yaml.org,2002:str', data, style='"')


yaml.add_representer(quoted, quoted_presenter)


class literal(str):
    pass


def literal_presenter(dumper, data):
    return dumper.represent_scalar('tag:yaml.org,2002:str', data, style='|')


yaml.add_representer(literal, literal_presenter)


def yamlfy(content: dict):
    atts = {}
    for k, v in content.items():
        if k.startswith('__') or not isinstance(v, str):
            continue
        if len(v) > 80:
            atts[k] = literal(v)
        else:
            atts[k] = quoted(v)
    return yaml.dump(atts)


def save_yaml(content: dict, path: str):
    with open(path, 'w', encoding='utf-8') as f:
        f.write(yamlfy(content))
