FROM --platform=linux/amd64 splunk/universalforwarder:9.4.2
USER root
# Install tools
RUN microdnf install -y acl sudo && microdnf clean all
# Fix stalled task and bind-mount EPERM by doing non-recursive shell chown instead of Ansible file module (which hits EPERM on virtiofs)
RUN printf -- "- name: Fast chown via shell\n  shell: chown splunk:splunk /opt/splunkforwarder/etc /opt/splunkforwarder/etc/apps || true\n  become: yes\n" > /opt/ansible/roles/splunk_common/tasks/change_splunk_directory_owner.yml
# Avoid HEC setup failure when splunk_httpinput app is missing from REST (404 on http input)
COPY set_as_hec_receiver.yml /opt/ansible/roles/splunk_common/tasks/set_as_hec_receiver.yml
# Create hafb app directory
RUN mkdir -p /opt/splunkforwarder/etc/apps/hafb/local && \
    chown -R splunk:splunk /opt/splunkforwarder/etc/apps/hafb
# Set permissions
RUN chown -R splunk:splunk /opt/splunkforwarder/etc /opt/splunkforwarder/var /opt/ansible/

USER splunk
