FROM splunk/splunk:9.4.2
USER root

# Install tools
RUN microdnf install -y acl sudo && microdnf clean all

# Copy over ansible config
COPY ansible.cfg /opt/ansible/ansible.cfg

# Fix stalled task and bind-mount EPERM by doing non-recursive shell chown instead of Ansible file module (which hits EPERM on virtiofs)
RUN printf -- "- name: Fast chown via shell\n  shell: chown splunk:splunk /opt/splunk/etc /opt/splunk/etc/apps || true\n  become: yes\n" > /opt/ansible/roles/splunk_common/tasks/change_splunk_directory_owner.yml

# Run update_etc script as root so it can cleanly extract initial configs into Docker's root-owned intermediate bind mount dirs
RUN sed -i 's/become_user: "{{ splunk.user }}"/become_user: root/g' /opt/ansible/roles/splunk_common/tasks/update_etc.yml

# Avoid HEC setup failure when splunk_httpinput app is missing from REST (404 on http input)
COPY set_as_hec_receiver.yml /opt/ansible/roles/splunk_common/tasks/set_as_hec_receiver.yml

# Disable Splunk's own monitoring and tune the web interface
RUN mkdir -p /opt/splunk/etc/system/local && \
    # Disable local log monitoring
    printf "[monitor://\$SPLUNK_HOME/var/log/splunk]\ndisabled = 1\n[monitor://\$SPLUNK_HOME/var/log/introspection]\ndisabled = 1\n" > /opt/splunk/etc/system/local/inputs.conf && \
    # Disable internal resource tracking (Introspection)
    printf "[introspection:resource_usage]\ndisabled = 1\n[introspection:disk_objects]\ndisabled = 1\n" > /opt/splunk/etc/system/local/telemetry.conf && \
    # UI tweaks
    printf "[settings]\nupdateCheckerBaseURL = 0\ntools.proxy.on = True\n" > /opt/splunk/etc/system/local/web.conf && \
    # Disable iowait health checks completely
    printf "[feature:iowait]\ndisabled = 1\n" > /opt/splunk/etc/system/local/health.conf

# Set permissions
RUN chown -R splunk:splunk /opt/splunk/etc /opt/splunk/var /opt/ansible/