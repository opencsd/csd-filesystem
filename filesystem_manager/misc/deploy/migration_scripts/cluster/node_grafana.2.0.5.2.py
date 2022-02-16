import json

# get hostnames 
host_file = open('/etc/hosts', 'r')
nodes = []

line = 'init '
while line:
    line = host_file.readline()
    if 'made by gms' in line and '-m' not in line:
        nodes.append(line.split(' ')[1])

# hostname sort
nodes.sort()
host_file.close()

# get node configuration
config_layout = open('/usr/gms/misc/grafana/prometheus_node.json', 'r').read().strip()
obj_config = json.loads(config_layout)

# generate configuration for multi nodes
cnt = 1
for config_row in obj_config['rows']:
    panel_template = config_row['panels'][0]
    config_row['panels'] = []
    _id = cnt * 50
    for node in nodes:
        tmp = panel_template
        tmp['id'] = _id 
        tmp_str = json.dumps(tmp)
        tmp_str = tmp_str.replace('{{hostname}}', node)
        config_row['panels'].append(json.loads(tmp_str))
        _id += 1
    cnt += 1

out_file = open('/tmp/prometheus_node.2.0.5.2.json', 'w')
out_file.write(json.dumps(obj_config))
out_file.close()
