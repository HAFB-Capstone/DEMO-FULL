FROM splunk/splunk:10.0
USER root

# Install tools
RUN microdnf install -y acl sudo && microdnf clean all

# Copy over ansible config
COPY ansible.cfg /opt/ansible/ansible.cfg

# Fix the stalled task by making it do nothing
RUN printf -- "- name: Bypassing slow chown\n  debug:\n    msg: 'Skipping recursive owner check'\n" > /opt/ansible/roles/splunk_common/tasks/change_splunk_directory_owner.yml

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

USER splunk