on run
	-- 可调参数
	set vmName to "wrt-studio"
	set bootDelaySeconds to 10 -- 登录后先等系统稳定，避免太早启动失败
	set maxRetry to 5 -- 启动重试次数
	set retryIntervalSeconds to 8 -- 每次重试间隔
	set waitReadyTimeoutSeconds to 60 -- 等待 UTM 就绪超时
	
	delay bootDelaySeconds
	
	try
		my waitForUTM(waitReadyTimeoutSeconds)
		
		tell application "UTM"
			activate
			set targetVM to first virtual machine whose name is vmName
			set vmStatus to status of targetVM
			
			if vmStatus is started or vmStatus is starting or vmStatus is resuming then
				return
			end if
		end tell
		
		repeat with i from 1 to maxRetry
			tell application "UTM"
				set targetVM to first virtual machine whose name is vmName
				set vmStatus to status of targetVM
				
				if vmStatus is started or vmStatus is starting or vmStatus is resuming then
					return
				end if
				
				start targetVM
			end tell
			
			delay retryIntervalSeconds
			
			tell application "UTM"
				set targetVM to first virtual machine whose name is vmName
				set vmStatus to status of targetVM
				if vmStatus is started or vmStatus is starting or vmStatus is resuming then
					return
				end if
			end tell
		end repeat
		
		error "重试 " & maxRetry & " 次后仍未成功启动虚拟机：" & vmName
		
	on error errMsg
		display dialog "UTM 自动启动失败：" & errMsg buttons {"好"} default button "好"
	end try
end run

on waitForUTM(timeoutSeconds)
	set elapsed to 0
	repeat while elapsed < timeoutSeconds
		try
			tell application "UTM"
				-- 读取属性用于探测 UTM AppleScript 接口是否可用
				count of virtual machines
			end tell
			return
		on error
			delay 2
			set elapsed to elapsed + 2
		end try
	end repeat
	error "等待 UTM 就绪超时（" & timeoutSeconds & " 秒）"
end waitForUTM
