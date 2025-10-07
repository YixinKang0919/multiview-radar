function ipv4Address = ipread()
    ipv4Pattern = '\d{1,3}(?:\.\d{1,3}){3}';

    if ispc
        % ---- Windows ----
        [~, cmdout] = system('ipconfig');
        startIndex = strfind(cmdout, 'Wi-Fi');
        if isempty(startIndex)
            ipv4Address = 'Wi-Fi adapter not found';
            return;
        end
        match = regexp(cmdout(startIndex:end), ipv4Pattern, 'match', 'once');
        if isempty(match), ipv4Address = 'No IPv4 address found for Wi-Fi adapter';
        else, ipv4Address = match;
        end
        return;
    elseif ismac
        % ---- macOS ----
        % Use full paths because MATLAB's PATH may not include /usr/sbin or /sbin
        listCmd = '/usr/sbin/networksetup -listallhardwareports';

        [status, hwports] = system(listCmd);
        if status ~= 0
            ipv4Address = 'Unable to list hardware ports';
            return;
        end

        % Find the device name for the Wi-Fi hardware port (e.g., en0 or en1)
        % Handles names like "Wi-Fi", "Wi-Fi", or "Wi-Fi 2"
        tok = regexp(hwports, 'Hardware Port:\s*Wi.?Fi[^\n]*\nDevice:\s*([^\s]+)', 'tokens', 'once');
        if isempty(tok)
            % Fallback: try common Wi-Fi interfaces
            candidateIfaces = {'en0','en1'};
        else
            candidateIfaces = {tok{1}};
        end

        ipv4Address = '';
        for k = 1:numel(candidateIfaces)
            iface = candidateIfaces{k};

            % Fast path: ipconfig getifaddr <iface>
            [s1, out1] = system(sprintf('/usr/sbin/ipconfig getifaddr %s', iface));
            ip = strtrim(out1);
            if s1 == 0 && ~isempty(regexp(ip, ['^' ipv4Pattern '$'], 'once'))
                ipv4Address = ip;
                return;
            end

            % Fallback: parse ifconfig
            [~, out2] = system(sprintf('/sbin/ifconfig %s', iface));
            m = regexp(out2, ['inet\s+(' ipv4Pattern ')'], 'tokens', 'once');
            if ~isempty(m)
                ipv4Address = m{1};
                return;
            end
        end

        if isempty(ipv4Address)
            ipv4Address = 'No IPv4 address found for Wi-Fi on macOS';
        end
        return;

    else
        % ---- Linux or others (optional bonus) ----
        % Try common Wi-Fi interface names
        candidateIfaces = {'wlan0','wlp2s0','wlp3s0','wlp0s20f3'};
        for k = 1:numel(candidateIfaces)
            iface = candidateIfaces{k};
            [~, out] = system(sprintf('ip -4 addr show %s', iface));
            m = regexp(out, ['inet\s+(' ipv4Pattern ')'], 'tokens', 'once');
            if ~isempty(m)
                ipv4Address = m{1};
                return;
            end
        end
        ipv4Address = 'No IPv4 address found for Wi-Fi on this OS';
    end
end
