--LUA Script to Read CANBUS Messages from Hondata KPRO or S300 Analog Channels
--Using Steinhart equation to convert Thermosister resistance to equivalent Temperature
--Last Update 30/09/2023
--Author: B Pham
--Email: bowzer6781@gmail.com
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
  --If Vout is nil then set a value for formula to execute
 if Vout == nil then
   Vout = 5
  end
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
  --use Steinhart equation and Coeffcients to calculate Temperature based on Resistance in Celsius
  local inv_temperature = A + B * math.log(Rt / Rr) + C * math.log(math.pow(Rt / Rr, 2)) + D * math.log(math.pow(Rt / Rr, 3))
  local temperature = 1/inv_temperature - 273.15

  return temperature
end

--Declare Virtual Channels, sample rate, precision, range and units
idA0 = addChannel("GearboxTemp", 5, 1, -20, 150, 'C')
idA1 = addChannel("OilTemp", 5, 1, -20, 150, 'C')

function getVoltage(b1, b2)
 repeat 
  id, ext, data = rxCAN(canBus, 1000)
  local voltage = 0
  if id == 1639 then
   local byte1 = toHEXString(data[b1])
   local byte2 = toHEXString(data[b2])

   --Concatenates the HEX values together and convert to Decimal
   local decimalvalue = tonumber(byte1..byte2, 16)
   --Calculate Decimal value devided by 819.2 Divider to obtain Voltage
   local voltage = decimalvalue/819.2
   return voltage
  end
  
 until id == nil
    println('Timeout: no CAN ID #1639 check CAN datalines')
end

function outputTemp(b1, b2)
 --Function to output the temperature using the various functions to calculate temperature based on voltage
 local voltage = getVoltage(b1, b2)
 local resistance = getResistance(voltage)
 local temperature = getTemperature (resistance)
 return temperature
end

function onTick()
 --Convert A0 Trans Temp Voltage to Temperature Bytes 1, 2
  TransTemp = outputTemp(1,2)
 --Convert A1 Oil Temp Voltage to Temperature Bytes 3, 4
  OilTemp = outputTemp(3,4)
 --Assign Temperatures to Virtual Channels
 setChannel(idA0, TransTemp)
 setChannel(idA1, OilTemp)
 println('')
 print('Transmission Temp on A0 is: '.. TransTemp)
 println('')
 print('      Engine Oil Temp on A1 is: '.. OilTemp)
 println('') 
end

setTickRate(30)
