-- Log messages from CAN bus
-- be sure to set the correct baud rate in the CAN settings

--------------------------------------------------
-- change this to 0 for CAN bus 1, or 1 for CAN bus 2
canBus = 0
--------------------------------------------------

function DECtoHEX(decimal)
  -- Check if the input is a number.
  if type(decimal) ~= "number" then
    return nil
  end

  -- Initialize the hexadecimal string.
  local hex_str = ""

  -- Repeat until the decimal number is zero.
  while decimal > 0 do
    -- Get the remainder of the division by 16.
    local remainder = decimal % 16

    -- Convert the remainder to a hexadecimal digit.
    local hex_digit = ""
    if remainder < 10 then
      hex_digit = string.char(remainder + 48)
    else
      hex_digit = string.char(remainder + 55)
    end

    -- Add the hexadecimal digit to the hexadecimal string.
    hex_str = hex_digit .. hex_str

    -- Divide the decimal number by 16.
    decimal = math.floor(decimal / 16)
  end

  -- Return the hexadecimal string.
  return hex_str
end


function toHEXString(dec_value)
 --Returns a concatenated Hex string and converts to string and to dec
 local hexstr = DECtoHEX(dec_value)
 -- If the HEX value contains only 1 character add 0
 if string.len(hexstr) == 1 then
   hexstr = '0' .. hexstr
  end
 return hexstr
end

function getResistance(Vout)
 --Calculates the R2 of a voltage divider circuit.
 --Vcc scaled to measured voltage on Hondata
 local Vcc = 4.8
 local R1 = 1500

  R2 = (Vout / (Vcc - Vout)) * R1
  return R2
end

function getTemperature(Rt)
  local Rr = 47000
  local A = 0.00335424143829873
  local B = 0.000263157894736842
  local C = -0.0000001322547409
  local D = 0

  local inv_temperature = A + B * math.log(Rt / Rr) + C * math.log(math.pow(Rt / Rr, 2)) + D * math.log(math.pow(Rt / Rr, 3))

  local temperature = 1/inv_temperature - 273.15

  return temperature
end

--Declare Channels
idA0 = addChannel("GearboxTemp", 5, 2, 0, 5, 'C')

function getVoltageA0()
 repeat 
  id, ext, data = rxCAN(canBus, 1000)
  local voltage = 0
  if id == 1639 then
   local byte1 = toHEXString(data[1])
   local byte2 = toHEXString(data[2])

   --Concatenates the HEX values together and convert to Decimal
   local decimalvalue = tonumber(byte1..byte2, 16)
   --voltage = tonumber(string.format("%.3f", decimalvalue/819.2))
   local voltage = decimalvalue/819.2
   return voltage
  end
  
 until id == nil
    println('Timeout: no CAN ID #1639 data')
end



function onTick()
 --outputCAN()
 --getVoltaA0()
 
 --Convert Voltage to Temperature
 voltageA0 = getVoltageA0()
 resistanceA0 = getResistance(voltageA0)
 temperatureA0 = getTemperature(resistanceA0)
 TransTemp = temperatureA0

 setChannel(idA0, TransTemp)
 println('')
 print('Transmission Temp is: '.. TransTemp)
 println('')
 
 --Test getChanel
 --test1 = getChannel(idA0)
 --print(test1) 
 
  
end

setTickRate(25)
