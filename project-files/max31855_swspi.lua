-- ***************************
-- *** max31855_swspi.lua ****
-- ***************************

-- NodeMCU driver module for Maxim MAX31855 thermocouple amplifier
-- by Patrick Lloyd


local max31855_softspi = {}

----------------------------
-- MODULE-SCOPE VARIABLES --
----------------------------

-- GPIO to be bit-banged
local cs_pin = 0
local miso_pin = 0
local sck_pin = 0

-- Control flags for various  
local setup_complete = false
local reading_bus = true

-- Container table for bit-banged SPI data
local raw = {}


---------------------------
---- PRIVATE FUNCTIONS ----
---------------------------


-- Bit-bang SPI bus to update 'raw' table
local function read32()
  -- Setting this flag allows functions to wait for data in a blocking loop
  reading_bus = true
  
  -- Select chip and give it a microsecond to become active
  gpio.write(cs_pin, gpio.LOW)
  tmr.delay(1)

  -- Cycle clock and read bus data into 'raw' 32 times
  for i = 1, 32 do
    gpio.write(sck_pin, gpio.HIGH)
    raw[i] = gpio.read(miso_pin)
    gpio.write(sck_pin, gpio.LOW)
    tmr.delay(1)
  end
  
  -- Deselect chip, wait 1 us, clear "busy" flag
  gpio.write(cs_pin, gpio.HIGH)
  tmr.delay(1)
  reading_bus = false
end


-- Allow number conversion from one base into any other number base
-- Only used for bin-to-hex conversion here but I'm leaving the generic
-- function because it's really cool! Based off of this function here:
-- http://giderosmobile.com/forum/discussion/comment/23186#Comment_23186
function base2base(in_num, in_base, out_base)
  -- Intermediate base change to 10
  local dec = tonumber(in_num, in_base)

  -- Control structure to actually print a zero if in_num == 0...
  -- Otherwise, just do the conversion
  if dec == 0 then
    return "0"
  else
    -- B is the base to be converted into
    -- K is the set of characters representing digits out to base 36
    -- out_num is the final result
    -- D is some intermediate variable during modulus operations
    --local B, K, out_num, D = out_base or 10,"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ",""
    local B, K = out_base or 10, "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local out_num, D = ""

    while dec > 0 do
      dec, D = math.floor(dec/B), (dec % B)+1
      out_num = string.sub(K,D,D)..out_num
    end

    return out_num
  end
end


-- Decodes temperature values either for TC or reference junction depending
-- on the bit width
function temp_decode(bin_value, temp_scale)
  
  -- Ignore sign bit for now and convert to decimal number
  local temp_c = tonumber(string.sub(bin_value, 2), 2)
  
  -- Heed the sign bit! 
  if string.sub(bin_value, 1, 1) == 1 then
    temp_c = temp_c * -1
  end

  -- Differentiate between TC or RJ and scale appropriately
  if #bin_value == 14 then
    temp_c = temp_c * 0.25
  elseif #bin_value == 12 then
    temp_c = temp_c * 0.0625
  end

  -- Dump output values into a table
  temp_calc = {
    ["c"] = temp_c,
    ["f"] = (temp_c * (9 / 5)) + 32
  }

  -- Make sure that you actually have the right arguments before you get output
  assert(temp_calc[temp_scale],
    "\nERROR: Temp scale argument for max31855_softspi.temp() not recognized.\n"..
    "Options are \"c\" for Celcius or \"f\" for fahrenheit.")

  return temp_calc[temp_scale]
end


--------------------------
---- PUBLIC FUNCTIONS ----
--------------------------


-- Setup function to set GPIO and update 'raw' once
function max31855_softspi.setup(user_cs, user_miso, user_sck)
  -- Give the rest of this module's functions access to the SoftSPI pins
  cs_pin = user_cs
  miso_pin = user_miso
  sck_pin = user_sck

  -- GPIO and default outputs
  gpio.mode(cs_pin, gpio.OUTPUT)
  gpio.write(cs_pin, gpio.HIGH)  -- chip not selected
  gpio.mode(sck_pin, gpio.OUTPUT)
  gpio.write(sck_pin, gpio.LOW)  -- idle low
  gpio.mode(miso_pin, gpio.INPUT)

  -- Allows for some flow control. Keeps the user from running things when
  -- things aren't right
  setup_complete = true

  -- Do a single read of the device to load up 'raw'
  read32()
  while reading_bus do end
end  


-- Print raw data in various formats. This does not update the 'raw' variable
-- so that if there is an intermittent error on the bus, you can check the
-- bits without potentially overwriting the error message 
function max31855_softspi.raw(format)
  assert(setup_complete,
    "\nERROR: Setup flag has not been set for max31855_softspi.setup()"..
    " function. Please run before continuing.")

  -- String to be filled and formatted
  local raw_out = ""

  -- Table of functions (coming from C, this concept blew my mind) that do the
  -- actual formatting of the output string
  printformat = {
    -- Raw bits, no frills
    ["bit"] = 
    function (x) raw_out = table.concat(raw) end,

    -- Same data as "bit" but with some helpful spacing
    ["bin"] =
    function (x)
        raw_out = "0b "..
        table.concat(raw, "", 1, 14).." "..   -- TC temp and sign
        table.concat(raw, "", 15, 15).." "..  -- Reserved
        table.concat(raw, "", 16, 16).." "..  -- Fault bit
        table.concat(raw, "", 17, 28).." "..  -- Ref junc temp
        table.concat(raw, "", 29, 29).." "..  -- Reserved
        table.concat(raw, "", 30, 32)         -- Fault Codes
    end,

    -- Just converts the 32 bit word into four bytes. There is no special
    -- formatting with respect to bit meaning
    ["hex"] = 
    function (x)
        -- Uses that cool private base2base function above
        raw_out = 
        "0x"..
        base2base(table.concat(raw, "", 1, 4), 2, 16)..
        base2base(table.concat(raw, "", 5, 8), 2, 16).." "..
        "0x"..
        base2base(table.concat(raw, "", 9, 12), 2, 16)..
        base2base(table.concat(raw, "", 13, 16), 2, 16).." "..
        "0x"..
        base2base(table.concat(raw, "", 17, 20), 2, 16)..
        base2base(table.concat(raw, "", 21, 24), 2, 16).." "..
        "0x"..
        base2base(table.concat(raw, "", 25, 28), 2, 16)..
        base2base(table.concat(raw, "", 29, 32), 2, 16)
    end
}

  assert(printformat[format],
    "\nERROR: Format argument for max31855_softspi.raw() not recognized.\n"..
    "Options are \"bit\", \"bin\"or \"hex\".")
  
  -- Update the output variable by running the corresponding table function
  printformat[format]()
  
  return raw_out
end

-- Return a table with floating point temperature values and the error bits
-- Sometimes you will get ridiculous (yet legal) temperature values when
-- certain errors happen. This puts error checking responsibility on the
-- receiving system, if it cares about such things.
function max31855_softspi.temp(dev, temp_scale)
  -- Check setup
  assert(setup_complete,
    "\nERROR: Setup flag has not been set for max31855_softspi.setup()"..
    " function.\nSetup device before continuing.")

  -- Update 'raw' data and wait for it to finish
  read32()
  while reading_bus do end

  -- Load a table with temp data from thermocouple and reference junction
  local device_temp = {
    ["rj"] = table.concat(raw, "", 17, 28),  
    ["tc"] = table.concat(raw, "", 1, 14)
  }

  -- Make sure the argument is legal
  assert(device_temp[dev],
    "\nERROR: Device argument for max31855_softspi.temp() not recognized.\n"..
    "Options are \"tc\" for thermocouple or \"rj\" for Reference Junction.")

  -- Get the floating point temperature value and error codes
  local temp = {
    ["value"] = temp_decode(device_temp[dev], temp_scale),
    ["err"] = table.concat(raw, "", 30, 32)
  }

  return temp
end

-- And Bob's your uncle
return max31855_softspi
