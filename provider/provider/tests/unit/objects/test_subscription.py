from unittest import TestCase

from provider.objects.subscription import Subscription


class SubscriptionTestCase(TestCase):
    def test_create(self):
        subscription = Subscription(name='test', categories=['test'])
        sid = subscription.create()
        self.assertIsNotNone(sid)
