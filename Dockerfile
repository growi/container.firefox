# Prepare Base Image
FROM fedora:latest AS base

RUN dnf update -y

FROM base

#Install Firefox
RUN dnf install -y \
    firefox

# Install Certificates for System

RUN \
    if [ -d /mnt/trustanchors ]; then \
        cp -r /mnt/trustanchors /tmp/trust \
        cp /tmp/trust/* /etc/pki/ca-trust/source/anchors/ \
        update-ca-trust; \
    fi

# Create Firefox Policy
ARG HOMEPAGES=https://www.redhat.com
ARG POLICY=/usr/lib64/firefox/distribution/policies.json

RUN \
    IFS=' ' read -ra pages <<< "$HOMEPAGES" && \
    echo -e '{'                                                               > $POLICY && \
    echo -e '    "policies": {'                                              >> $POLICY && \
                     #Suppress FirstStart Page
    echo -e '        "OverrideFirstRunPage" : "",'                           >> $POLICY && \
                     #Set Start Pages
    echo -e '        "Homepage": {'                                          >> $POLICY && \
    echo -e '            "URL": "'${pages[0]}'",'                            >> $POLICY && \
    echo -e '            "Locked": true,'                                    >> $POLICY && \
    echo -e '            "Additional": ['                                    >> $POLICY && \

    if [ ${#pages[@]} -gt 1 ]; then  \
        ind=$(printf ' %.0s' {1..16}) \
        ADD=$(for p in ${pages[@]:1:${#pages}-1}; do echo "$ind\"${p}\","; done) && \
        (IFS=$"\n"; echo -e ${ADD:0:${#ADD}-1})                              >> $POLICY; \
    fi && \

    echo -e '            ],'                                                 >> $POLICY && \
    echo -e '            "StartPage": "homepage"'                            >> $POLICY && \
    echo -e '        },'                                                     >> $POLICY && \
                     #Install additional Certificates
    echo -e '        "Certificates": {'                                      >> $POLICY && \
    echo -e '            "Install": ['                                       >> $POLICY && \

    if [ -d /tmp/trust ]; then  \
        ind=$(printf ' %.0s' {1..16}) \
        CERTS=$(for f in /tmp/trust/*; do echo "$ind\"$f\","; done) && \
        (IFS=$"\n"; echo -e ${CERTS:0:${#CERTS}-1})                          >> $POLICY; \
    fi && \

    echo -e '            ]'                                                  >> $POLICY && \
    echo -e '        }'                                                      >> $POLICY && \
    echo -e '    }'                                                          >> $POLICY && \
    echo -e '}'                                                              >> $POLICY

# Configure Firefox
RUN \
    # Suppress Privacy Notification
    echo -e 'pref("datareporting.policy.dataSubmissionPolicyBypassNotification", true);'     > /usr/lib64/firefox/defaults/pref/autoconfig.js && \
    # Set global Config File
    echo -e 'pref("general.config.filename", "firefox.cfg");'                               >> /usr/lib64/firefox/defaults/pref/autoconfig.js && \
    # Disable Obfuscation for Firefox Config
    echo -e 'pref("general.config.obscure_value", 0);'                                      >> /usr/lib64/firefox/defaults/pref/autoconfig.js && \
    cat /usr/lib64/firefox/defaults/pref/autoconfig.js

# Enable Firefox Policy
RUN \
    # Disable User specific Policy Overrides
    echo -e '//Enable policies.json'                              > /usr/lib64/firefox/firefox.cfg && \
    echo -e 'lockPref("browser.policies.perUserDir", false);'    >> /usr/lib64/firefox/firefox.cfg && \
    cat /usr/lib64/firefox/firefox.cfg

RUN cat $POLICY

#Configure Entrypoint 
ENTRYPOINT ["firefox", "--new-instance"]

#Example 'podman build' Command
# podman build . -v ~/trustanchors:/mnt/trustanchors:ro,z --build-arg HOMEPAGES="https://www.redhat.com https://www.google.com" -t firefox

#Example 'podman run' Command
# podman run -it --rm -v $XAUTHORITY:$XAUTHORITY:ro -v /tmp/.X11-unix:/tmp/.X11-unix:ro --userns keep-id --workdir=/tmp -e "DISPLAY" --network=host --ipc=host --cap-add=NET_ADMIN --security-opt label=type:container_runtime_t firefox


