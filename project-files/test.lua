-- Manually-run test file

-- example raw data to play with
-- raw = {0,0,0,0, 0,0,0,1, 0,0,0,1, 1,0, 0, 0, 0,0,0,1, 1,0,1,0, 0,0,1,0, 0, 0,0,0}

--local maxxx = require "max31855_swspi"
maxxx = require "max31855_swspi"  -- Global for interactive interpreter use

-- Pin definitions
sspi_sck = 1 
sspi_miso = 2 
sspi_cs = 3

maxxx.setup(sspi_cs, sspi_miso, sspi_sck)
print(maxxx.raw("bin"))

t = maxxx.temp("tc","c")
print("Thermocouple Value: "..t["value"].."°C")
print("Thermocouple Error: "..t["err"])

-- t = maxxx.temp("tc", "f")

-- print("TC Value: "..t["value"])
-- print("TC Error: "..t["err"])