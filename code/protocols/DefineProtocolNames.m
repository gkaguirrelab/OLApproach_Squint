function theProtocols = DefineProtocolNames()

% Defines the protocol used by this approach
%
% This gets called by OLApproach_SquintLocalHook to set up the
% preferences for datapaths.

%% Define protocols for this approach
theProtocols = { ...
    'SquintToPulse' ...
    'Screening', ...
    'Deuteranopes'
    };

end