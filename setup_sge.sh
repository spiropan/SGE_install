# Configure the master hostname for Grid Engine
echo "gridengine-master       shared/gridenginemaster string  $HOSTNAME" | sudo debconf-set-selections
echo "gridengine-master       shared/gridenginecell   string  default" | sudo debconf-set-selections
echo "gridengine-master       shared/gridengineconfig boolean false" | sudo debconf-set-selections
echo "gridengine-common       shared/gridenginemaster string  $HOSTNAME" | sudo debconf-set-selections
echo "gridengine-common       shared/gridenginecell   string  default" | sudo debconf-set-selections
echo "gridengine-common       shared/gridengineconfig boolean false" | sudo debconf-set-selections
echo "gridengine-client       shared/gridenginemaster string  $HOSTNAME" | sudo debconf-set-selections
echo "gridengine-client       shared/gridenginecell   string  default" | sudo debconf-set-selections
echo "gridengine-client       shared/gridengineconfig boolean false" | sudo debconf-set-selections

# Postfix mail server is also installed as a dependency
echo "postfix postfix/main_mailer_type        select  No configuration" | sudo debconf-set-selections

# Install Grid Engine
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y gridengine-master gridengine-client

# Set up Grid Engine
sudo -u sgeadmin /usr/share/gridengine/scripts/init_cluster /var/lib/gridengine default /var/spool/gridengine/spooldb sgeadmin
sudo service gridengine-master restart

# Disable Postfix
sudo service postfix stop
sudo update-rc.d postfix disable

# add the current host to the submit host list (will be able to do qsub)
sudo qconf -as $HOSTNAME

# install and configure worker
echo "gridengine-common       shared/gridenginemaster string  $MASTER_HOSTNAME" | sudo debconf-set-selections
echo "gridengine-common       shared/gridenginecell   string  default" | sudo debconf-set-selections
echo "gridengine-common       shared/gridengineconfig boolean false" | sudo debconf-set-selections
echo "gridengine-client       shared/gridenginemaster string  $MASTER_HOSTNAME" | sudo debconf-set-selections
echo "gridengine-client       shared/gridenginecell   string  default" | sudo debconf-set-selections
echo "gridengine-client       shared/gridengineconfig boolean false" | sudo debconf-set-selections
echo "postfix postfix/main_mailer_type        select  No configuration" | sudo debconf-set-selections

sudo DEBIAN_FRONTEND=noninteractive apt-get install -y gridengine-exec gridengine-client

sudo service postfix stop
sudo update-rc.d postfix disable

# add yourself to the manager list
sudo qconf -am $USER

# add yourself to the operator list (will be able to add/remove workers)
sudo qconf -ao $USER

# create a host list
echo -e "group_name @allhosts\nhostlist NONE" > ./grid
sudo qconf -Ahgrp ./grid
rm ./grid


# create a queue called all.q
cat > ./grid <<EOL
qname                 peteris.q
hostlist              @allhosts
seq_no                0
load_thresholds       NONE
suspend_thresholds    NONE
nsuspend              1
suspend_interval      00:00:01
priority              0
min_cpu_interval      00:00:01
processors            UNDEFINED
qtype                 BATCH INTERACTIVE
ckpt_list             NONE
pe_list               make
rerun                 FALSE
slots                 2
tmpdir                /tmp
shell                 /bin/csh
prolog                NONE
epilog                NONE
shell_start_mode      posix_compliant
starter_method        NONE
suspend_method        NONE
resume_method         NONE
terminate_method      NONE
notify                00:00:01
owner_list            NONE
user_lists            NONE
xuser_lists           NONE
subordinate_list      NONE
complex_values        NONE
projects              NONE
xprojects             NONE
calendar              NONE
initial_state         default
s_rt                  INFINITY
h_rt                  INFINITY
s_cpu                 INFINITY
h_cpu                 INFINITY
s_fsize               INFINITY
h_fsize               INFINITY
s_data                INFINITY
h_data                INFINITY
s_stack               INFINITY
h_stack               INFINITY
s_core                INFINITY
h_core                INFINITY
s_rss                 INFINITY
h_rss                 INFINITY
s_vmem                INFINITY
h_vmem                INFINITY
EOL
sudo qconf -Aq ./grid
rm ./grid

# Here add hostname as a worker with desired number of slots
num_cpus=$(grep -c ^processor /proc/cpuinfo)
slots=$(echo "$num_cpus-1" | bc)
sudo ./add_worker.sh all.q $HOSTNAME $slots
