%packages
# Apache (used for wiki...only for queen)
httpd
%end


#################################################################################
%post
/sbin/chkconfig httpd on 2>/dev/null
%end
