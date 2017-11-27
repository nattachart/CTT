function parseHexString(str) { 
	var result = [];
	while (str.length >= 2) { 
		result.push(parseInt(str.substring(0, 2), 16));
		str = str.substring(2, str.length);
	}

	return result;
}

//const util = require('util');

//var hex;
//hex = parseHexString("3C3D3E064A22557863D93742DB776D74726F6F6676332D312329B10300AF01AD54E38540B0000001CCF4F5434A0AD7C3404C00FB1A424D8150C3474600000000470000000048000000000600000000");
//console.log(hex);

function getStartDelimiter(payload){
	var sd = String.fromCharCode(payload[0]) + String.fromCharCode(payload[1]) + String.fromCharCode(payload[2]);
	return sd;
}
function getFrameType(payload){
	return payload[3];
}
function getNumberOfBytes(payload){
	return payload[4];
}
function getSeparatorCharCode(payload){
	return 0x23;
}
function getSerialID(payload){
	var start = 5;
	var sid = "";
	for(var i=start; i<start+8; i++){
		sid += payload[i].toString(16);
	}
	return sid;
}
function getWaspmoteIDEndIndex(payload, separatorCode){
	var index = 13; //The starting index of the Waspmote ID
		while(payload[index] != separatorCode){
			index++;
		}
	return index-1;
}
function getFrameSequence(payload, wIDEndIndex){
	return payload[wIDEndIndex + 2];
}
function getStartPayloadIndex(wIDIndex){
	return wIDIndex + 3;
}
function getUInt16(payload, startByte){
	//Little endian
		var value = payload[startByte + 1];
	value <<= 8;
	value |= payload[startByte] & 0x00FF;
	return value;
}
function getFloat(payload, startByte){
	//Little endian
		/*var value = (payload[startByte + 3] << 24) && 0xFF000000;
		  value |= (payload[startByte + 2] << 16) & 0x00FF0000;
		  value |= (payload[startByte + 1] << 8) & 0x0000FF00;
		  value |= payload[startByte] & 0x000000FF;*/
		var negative = (payload[startByte + 3] & 0x80) !== 0; //If the msb is set, the number is negative.
		var exponent = payload[startByte + 3] & 0x7F;
	exponent <<= 1;
	exponent |= (0x80 & payload[startByte + 2]) >> 7;
	console.log(exponent);
	var decimal = (0x7F & payload[startByte + 2]) << 8;
	decimal |= payload[startByte + 1];
	decimal <<= 8;
	decimal |= payload[startByte];
	console.log(decimal.toString(16));
	exponent -= 127; //Subtract the exponent bias (127) from the excess.
		console.log(exponent);
	var fraction = 1;
	for(var i=0; i < 23; i++){
		fraction += (((((decimal & (1 << (22 - i))) >> (22-i)) & 1) !== 0) ? Math.pow(2, -(i+1)) : 0);
	}
	var value = fraction * Math.pow(2, exponent);
	value = negative ? -value : value;
	return value;
}
function getFirmwareVersion(payload, startPayloadIndex){
	return getUInt16(payload, startPayloadIndex+1);
}
function getFlags(payload, startPayloadIndex){
	return payload[startPayloadIndex + 4];
}
function getBatteryVoltage(payload, startPayloadIndex){
	return getFloat(payload, startPayloadIndex + 6);
}
function getBatteryLevel(payload, startPayloadIndex){
  var volts = getBatteryVoltage(payload, startPayloadIndex);
  var bits = volts * 1023 / 3.3;
  var aux = bits / 2.0;
  if(aux < 512)
      return 0;
  else if(aux > 651)
      return 100;
  else if(aux > 543)
      return (aux * (90.0 / 108.0)) - 442.0;
  else
      return ((10.0 / (543.0 - 511.0)) * aux) - 160.0;
}
function getSolarChargeCurrent(payload, startPayloadIndex){
	return getUInt16(payload, startPayloadIndex + 11);
}
function getCO2(payload, startPayloadIndex){
	return getFloat(payload, startPayloadIndex + 14);
}
function getTemperature(payload, startPayloadIndex){
	return getFloat(payload, startPayloadIndex + 19);
}
function getHumidity(payload, startPayloadIndex){
	return getFloat(payload, startPayloadIndex + 24);
}
function getPressure(payload, startPayloadIndex){
	return getFloat(payload, startPayloadIndex + 29);
}
function getPM1(payload, startPayloadIndex){
	return getFloat(payload, startPayloadIndex + 34);
}
function getPM2_5(payload, startPayloadIndex){
	return getFloat(payload, startPayloadIndex + 39);
}
function getPM10(payload, startPayloadIndex){
	return getFloat(payload, startPayloadIndex + 44);
}
function getNO2(payload, startPayloadIndex){
	return getFloat(payload, startPayloadIndex + 49);
}
function getDownSeq(payload, startPayloadIndex){
        return getUInt16(payload, startPayloadIndex + 54);
}
function getMode(payload, startPayloadIndex){
        return getUInt16(payload, startPayloadIndex + 57);
}


function Decoder(bytes, port) {
  // Decode an uplink message from a buffer
  // (array) of bytes to an object of fields.
  
  var startDelim = getStartDelimiter(bytes);
  var frameType = getFrameType(bytes);
  var numBytes = getNumberOfBytes(bytes);
  var sep = getSeparatorCharCode(bytes);
  var sid = getSerialID(bytes);
  var wIDEndIndex = getWaspmoteIDEndIndex(bytes, sep);
  var frameSeq = getFrameSequence(bytes, wIDEndIndex);
  var sPIdx = getStartPayloadIndex(wIDEndIndex);
  var fVer = getFirmwareVersion(bytes, sPIdx);
  var flags = getFlags(bytes, sPIdx);
  var battVolt = getBatteryVoltage(bytes, sPIdx);
  var battLevel = getBatteryLevel(bytes, sPIdx);
  var solar = getSolarChargeCurrent(bytes, sPIdx);
  var co2 = getCO2(bytes, sPIdx);
  var temperature = getTemperature(bytes, sPIdx);
  var humidity = getHumidity(bytes, sPIdx);
  var pressure = getPressure(bytes, sPIdx);
  var pm1 = getPM1(bytes, sPIdx);
  var pm2_5 = getPM2_5(bytes, sPIdx);
  var pm10 = getPM10(bytes, sPIdx);
  var no2 = getNO2(bytes, sPIdx);
  var downSeq = getDownSeq(bytes, sPIdx);
  var mode = getMode(bytes, sPIdx);
  
  var decoded = {"version":fVer,
  "flags":flags,
  "batteryVolt":battVolt,
  "batteryLevel":battLevel,
  "solarCharge":solar,
  "co2":co2,
  "temperature":temperature,
  "humidity":humidity,
  "pressure":pressure,
  "pm1":pm1,
  "pm2_5":pm2_5,
  "pm10":pm10,
  "no2":no2,
  "downSeq":downSeq,
  "mode":mode
  };
  //var decoded = [0];
  // if (port === 1) decoded.led = bytes[0];

  return decoded;
}