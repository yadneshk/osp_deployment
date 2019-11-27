import os,time

node_state_cmd = "openstack baremetal node list | awk '{print $11}'| awk 'NR > 2'"
import_nodes_cmd = "openstack overcloud node import /home/stack/instackenv.json &> /dev/null"
introspect_nodes_cmd = "openstack overcloud node introspect --all-manageable  --provide &/ dev/null"
start_vms = ""
stop_vms = ""
deploy_cmd = ""

def introspect():
	print "Importing nodes"
	os.system(import_nodes_cmd)

	while :
		if ( len(set(os.popen(node_state_cmd).read().split())) == 1 and set(os.popen(node_state_cmd).read().split())[0] == "manageable" ):
			print "all nodes in manageable"
			break
		else:
			print "waiting for nodes to enter manageable state"
		time.sleep(90)

	print "Starting introspection"
	os.system(introspect_nodes_cmd)

	while :
		if ( len(set(os.popen(node_state_cmd).read().split())) == 1 and set(os.popen(node_state_cmd).read().split())[0] == "wait call-back" ):
			print "all nodes in wait call-back\npowering on nodes"
			os.system(start_vms)
			break
		else:
			print "waiting for nodes to enter wait call-back state"
		time.sleep(90)

	while :
		if ( len(set(os.popen(node_state_cmd).read().split())) == 1 and set(os.popen(node_state_cmd).read().split())[0] == "active"):
			print "all nodes in active\npowering on nodes"
			os.system(start_vms)
			break
		else:
			print "waiting for nodes to enter active state"
		time.sleep(90)


	while :
		if ( len(set(os.popen(node_state_cmd).read().split())) == 1 and set(os.popen(node_state_cmd).read().split())[0] == "available"):
			print "all nodes in available\nexecute deploy command now"
			os.system(deploy_cmd)
			break
		else:
			print "waiting for nodes to enter available state"
		time.sleep(90)			


def deploy():
	while :
		if ( len(set(os.popen(node_state_cmd).read().split())) == 1 and set(os.popen(node_state_cmd).read().split())[0] == "wait call-back" ):
			print "all nodes in wait call-back\npowering on nodes"
			os.system(start_vms)
			break
		else:
			print "waiting for nodes to enter wait call-back state"
		time.sleep(90)

	while :
		if ( len(set(os.popen(node_state_cmd).read().split())) == 1 and set(os.popen(node_state_cmd).read().split())[0] == "active"):
			print "all nodes in active\npowering on nodes"
			os.system(start_vms)
			break
		else:
			print "waiting for nodes to enter active state"
		time.sleep(90)

introspect()
deploy()
	