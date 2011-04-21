#!/bin/bash

tmux new-session -d -s example 'tail -n 100 -f /var/log/messages' 	\; \
     split-window -h 'watch -n1 "free -m"'				\; \
     split-window -v 'top'						\; \
     split-window -v 'watch -n1 "netstat -tulpan 2>/dev/null"'		\; \
     new-window -n 'htop' htop						\; \
     select-window -t 1							\; \
     attach
