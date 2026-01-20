program test_exec
  integer :: i

  call execute_command_line ("bash start.sh extra_info", exitstat=i)
  print *, "Exit status of 'bash start.sh' was ", i

  !call execute_command_line ("reindex_files.exe", wait=.false.)
  !print *, "Now reindexing files in the background"

end program test_exec
