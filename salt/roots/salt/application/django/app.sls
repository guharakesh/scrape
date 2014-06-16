
include:
  - pkg.git
{% if 'develop' in grains['roles'] %}
  - postgresql-server.93
{% endif %}

{% set apps = [] %}
{% for k,v in pillar.items() %}
  {% if k.startswith('django-app') %}
    {% do apps.append(v) %}
  {% endif %}
{% endfor %}

{% for app in apps %}

{% set app_name = app['friendly_name'] %}

{% if 'develop' in grains['roles'] %}
{{ app_name }}_postgres_pg_hba:
  file.managed:
    - name: /var/lib/pgsql/9.3/data/pg_hba.conf
    - source: salt://application/django/config/test-pg_hba.conf
    - user: postgres
    - group: postgres
    - mode: 600
    - require:
      - pkg: postgresql93-server
      - cmd: postgresql93-server

{{ app_name }}_dev_postgres_user:
  postgres_user.present:
    - name: bookwork
    - password: bookwork
    - user: postgres
    - require:
      - service: postgresql-9.3

{{ app_name }}_postgres_database:
  postgres_database.present:
    - name: bookwork
    - owner: bookwork
    - require:
      - postgres_user: bookwork

{{ app_name }}-iptables:
  service:
    - name: iptables
    - dead
    - disable: True
{% endif %}

{{ app_name }}-python-deps:
  pkg.installed:
    - pkgs:
      - python
      - python-devel
      - make
      - gcc
      - python-virtualenv

{{ app_name }}-user:
  group.present:
    - name: {{ app_name }}
  user.present:
    - name: {{ app_name }}
    - home: /home/{{ app_name }}
    - gid: {{ app_name }}
    - require:
      - group: {{ app_name }}

/home/{{ app_name }}:
  file.directory:
    - mode: 750
    - require:
      - user: {{ app_name }}

/home/{{ app_name }}/.ssh:
  file.directory:
    - user: {{ app_name }}
    - group: {{ app_name }}
    - mode: 700
    - makedirs: True

/home/{{ app_name }}/.ssh/id_rsa:
  file.managed:
    - context:
      app_name: {{ app['name'] }}
    - user: {{ app_name }}
    - group: {{ app_name }}
    - mode: 600
    - source: salt://application/django/config/private_key.jinja
    - template: jinja
    - require:
      - file: /home/{{ app_name }}/.ssh
      - user: {{ app_name }}

github.com-{{ app_name }}:
  ssh_known_hosts:
    - name: github.com
    - present
    - user: {{ app_name }}
    - hash_hostname: False
    - fingerprint: 16:27:ac:a5:76:28:2d:36:63:1b:56:4d:eb:df:a6:48

{{ app_name }}-source:
  git.latest:
    - name: {{ app['source'] }}
    - rev: {{ app['revision'] }}
    - target: /home/{{ app_name }}/app
    - runas: {{ app_name }}
    - require:
      - pkg: git
      - user: {{ app_name }}
      - file: /home/{{ app_name }}/.ssh/id_rsa
      - ssh_known_hosts: github.com-{{ app_name }}

{{ app_name }}-virtualenv:
  virtualenv.managed:
    - name: /home/{{ app_name }}/app/env
    - system_site_packages: False
    - runas: {{ app_name }}
    - cwd: /home/{{ app_name }}/app
    - no_chown: True
{% if 'develop' in grains['roles'] %}
    - requirements: /home/{{ app_name }}/app/develop-requirements.txt
{% else %}
    - requirements: /home/{{ app_name }}/app/requirements.txt
{% endif %}
    - require:
      - git: {{ app_name }}-source
      - pkg: {{ app_name }}-python-deps
{% if 'system-deps' in app %}
      - pkg: {{ app_name }}-system-deps

{{ app_name }}-system-deps:
  pkg.installed:
    - pkgs:
      {% for package in app['system-deps'] %}
      - {{ package }}
      {% endfor %}
{% endif %}

{% if 'develop' in grains['roles'] %}

{% endif %}

{% endfor %}
