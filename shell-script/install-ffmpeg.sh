#! /bin/bash

cat <<EOF >> /etc/portage/package.use/ffmpeg
media-video/ffmpeg opus svt-av1
EOF

emerge --ask --verbose media-video/ffmpeg
