from getpass import getpass
import requests
import subprocess


url = 'https://localhost:8006/api2/json'
requests.urllib3.disable_warnings()


def authenticate():
    username = input('Username: ')
    password = getpass('Password: ')
    resp = requests.post('{}/access/ticket?username={}@pve&password={}'.format(url, username, password), verify=False)
    if resp.status_code != 200:
        return None
    else:
        return {
            'Cookie': 'PVEAuthCookie={}'.format(resp.json()['data']['ticket'])
        }


def get_nodes(headers):
    nodes = []
    resp = requests.get('{}/nodes'.format(url), verify=False, headers=headers)
    if resp.status_code == 200:
        for n in resp.json()['data']:
            nodes.append(n['node'])
    return nodes


def get_user_vm(headers):
    resp = requests.get('{}/access/permissions'.format(url), verify=False, headers=headers)
    if resp.status_code != 200:
        return None
    else:
        vms = []
        for v in resp.json()['data']:
            tmp = v.split('/')
            if tmp[1] == 'vms':
                vms.append(tmp[2])

        vm = None
        if len(vms) > 0:
            vm = int(vms[0])
            if len(vms) > 1:
                pass
        return vm


def get_user_vm_info(headers, vm):
    nodes = get_nodes(headers)
    for n in nodes:
        resp = requests.get('{}/nodes/{}/qemu'.format(url, n), verify=False, headers=headers)
        if resp.status_code == 200:
            for v in resp.json()['data']:
                if v['vmid'] == vm:
                    return n, v
    return None, None


def get_connection_data(headers, vm):
    node, info = get_user_vm_info(headers, vm)
    if node is None or info is None:
        return None, None

    if info['status'] != 'running':
        return None, None

    resp = requests.get('{}/nodes/{}/network'.format(url, node), verify=False, headers=headers)
    if resp.status_code != 200:
        return None, None
    else:
        for i in resp.json()['data']:
            if i['type'] != 'bridge':
                return i['address'], (5900 + vm)


def connect_to_vnc(ip, port):
    with open('/home/imslab/default.tig', 'r') as r, open('/home/imslab/running.tig', 'w') as w:
        tig = r.readlines()
        for l in tig:
            if l == 'ServerName=\n':
                w.write('ServerName={}:{}\n'.format(ip, port))
            else:
                w.write(l)
    subprocess.run(['vncviewer', '/home/imslab/running.tig'])


def exit_with_error(msg):
    print(msg)
    input('Press ENTER to continue...')


if __name__ == '__main__':
    try:
        auth_header = authenticate()
        if auth_header is None:
            exit_with_error('Authentication failure')
        else:
            user_vm = get_user_vm(auth_header)
            if user_vm is None:
                exit_with_error('No VMs are assigned to user')
            else:
                vnc_ip, vnc_port = get_connection_data(auth_header, user_vm)
                if vnc_ip is None or vnc_port is None:
                    exit_with_error('No running VMs found')
                else:
                    connect_to_vnc(vnc_ip, vnc_port)
    except Exception as e:
        exit_with_error('Error occured: ' + str(e))
