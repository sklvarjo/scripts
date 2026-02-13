tmux new-session -d -n "static" -s "megasense" # create new session , detached
tmux send-keys -t 0 "echo static" Enter # this actually launches `glances` in my first window

tmux new-window -n "mon3"
tmux send-keys -t 0 "echo mon3" Enter
#tmux split-window -h -p 30 # split it into two halves
#tmux resize-pane -x 95
#tmux select-pane -t 0 # go back to the first pane

tmux new-window -n "fast"
tmux send-keys -t 0 "echo fast" Enter
#tmux split-window -h -p 30 # split it into two halves
#tmux select-pane -t 0 # go back to the first pane
#tmux send-keys -t 0 "cd work" Enter # change to specific subdir for these two panes
#tmux send-keys -t 1 "cd work" Enter

# etc..you can keep adding more new windows as needed..

sleep 1 # not sure why I had this...

tmux select-window -t "megasense:static" # go back to the first window
tmux attach-session -d
