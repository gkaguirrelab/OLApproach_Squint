function testEMG(protocolParams)

emgOutput = SquintRecordEMG(...
                'recordingDurationSecs', 5, ...
                'simulate', false, ...
                'verbose', true);
            
end