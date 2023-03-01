`cat > test.info <<EOF
d-i partman-auto/expert_recipe string                         
      root-opt ::                                             
			512 10000 512 ext4                    
				$primary{ } $bootable{ }                
				method{ format } format{ }              
				use_filesystem{ } filesystem{ ext4 }    
				mountpoint{ /boot }                         
			.                                               
			102400 10000 102400 ext4                          
				$primary{ }                             
				method{ format } format{ }              
				use_filesystem{ } filesystem{ ext4 }    
				mountpoint{ / }                      
			.                      
			1024 10000 1024 linux-swap                      
				$primary{ }                
				method{ swap } format{ }
EOF`
