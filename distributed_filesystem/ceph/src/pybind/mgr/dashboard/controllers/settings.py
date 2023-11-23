# -*- coding: utf-8 -*-
from contextlib import contextmanager

import cherrypy

from ..security import Scope
from ..settings import Options
from ..settings import Settings as SettingsModule
from . import APIDoc, APIRouter, EndpointDoc, RESTController, UIRouter

SETTINGS_SCHEMA = [{
    "name": (str, 'Settings Name'),
    "default": (bool, 'Default Settings'),
    "type": (str, 'Type of Settings'),
    "value": (bool, 'Settings Value')
}]


@APIRouter('/settings', Scope.CONFIG_OPT)
@APIDoc("Settings Management API", "Settings")
class Settings(RESTController):
    """
    Enables to manage the settings of the dashboard (not the Ceph cluster).
    """
    @contextmanager
    def _attribute_handler(self, name):
        """
        :type name: str|dict[str, str]
        :rtype: str|dict[str, str]
        """
        if isinstance(name, dict):
            result = {
                self._to_native(key): value
                for key, value in name.items()
            }
        else:
            result = self._to_native(name)

        try:
            yield result
        except AttributeError:  # pragma: no cover - handling is too obvious
            raise cherrypy.NotFound(result)  # pragma: no cover - handling is too obvious

    @staticmethod
    def _to_native(setting):
        return setting.upper().replace('-', '_')

    @EndpointDoc("Display Settings Information",
                 parameters={
                     'names': (str, 'Name of Settings'),
                 },
                 responses={200: SETTINGS_SCHEMA})
    def list(self, names=None):
        """
        Get the list of available options.
        :param names: A comma separated list of option names that should
        be processed. Defaults to ``None``.
        :type names: None|str
        :return: A list of available options.
        :rtype: list[dict]
        """
        option_names = [
            name for name in Options.__dict__
            if name.isupper() and not name.startswith('_')
        ]
        if names:
            names = names.split(',')
            option_names = list(set(option_names) & set(names))
        return [self._get(name) for name in option_names]

    def _get(self, name):
        with self._attribute_handler(name) as sname:
            setting = getattr(Options, sname)
        return {
            'name': sname,
            'default': setting.default_value,
            'type': setting.types_as_str(),
            'value': getattr(SettingsModule, sname)
        }

    def get(self, name):
        """
        Get the given option.
        :param name: The name of the option.
        :return: Returns a dict containing the name, type,
        default value and current value of the given option.
        :rtype: dict
        """
        return self._get(name)

    def set(self, name, value):
        with self._attribute_handler(name) as sname:
            setattr(SettingsModule, self._to_native(sname), value)

    def delete(self, name):
        with self._attribute_handler(name) as sname:
            delattr(SettingsModule, self._to_native(sname))

    def bulk_set(self, **kwargs):
        with self._attribute_handler(kwargs) as data:
            for name, value in data.items():
                setattr(SettingsModule, self._to_native(name), value)


@UIRouter('/standard_settings')
class StandardSettings(RESTController):
    def list(self):
        """
        Get various Dashboard related settings.
        :return: Returns a dictionary containing various Dashboard
        settings.
        :rtype: dict
        """
        return {  # pragma: no cover - no complexity there
            'user_pwd_expiration_span':
            SettingsModule.USER_PWD_EXPIRATION_SPAN,
            'user_pwd_expiration_warning_1':
            SettingsModule.USER_PWD_EXPIRATION_WARNING_1,
            'user_pwd_expiration_warning_2':
            SettingsModule.USER_PWD_EXPIRATION_WARNING_2,
            'pwd_policy_enabled':
            SettingsModule.PWD_POLICY_ENABLED,
            'pwd_policy_min_length':
            SettingsModule.PWD_POLICY_MIN_LENGTH,
            'pwd_policy_check_length_enabled':
            SettingsModule.PWD_POLICY_CHECK_LENGTH_ENABLED,
            'pwd_policy_check_oldpwd_enabled':
            SettingsModule.PWD_POLICY_CHECK_OLDPWD_ENABLED,
            'pwd_policy_check_username_enabled':
            SettingsModule.PWD_POLICY_CHECK_USERNAME_ENABLED,
            'pwd_policy_check_exclusion_list_enabled':
            SettingsModule.PWD_POLICY_CHECK_EXCLUSION_LIST_ENABLED,
            'pwd_policy_check_repetitive_chars_enabled':
            SettingsModule.PWD_POLICY_CHECK_REPETITIVE_CHARS_ENABLED,
            'pwd_policy_check_sequential_chars_enabled':
            SettingsModule.PWD_POLICY_CHECK_SEQUENTIAL_CHARS_ENABLED,
            'pwd_policy_check_complexity_enabled':
            SettingsModule.PWD_POLICY_CHECK_COMPLEXITY_ENABLED
        }
