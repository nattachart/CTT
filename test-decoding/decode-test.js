function parseHexString(str) { 
	var result = [];
	while (str.length >= 2) { 
		result.push(parseInt(str.substring(0, 2), 16));
		str = str.substring(2, str.length);
	}

	return result;
}

const util = require('util');

var hex;
hex = parseHexString("3C3D3E064A22557863D93742DB776D74726F6F6676332D312329B10300AF01AD54E38540B0000001CCF4F5434A0AD7C3404C00FB1A424D8150C3474600000000470000000048000000000600000000");
console.log(hex);

for(var i=0; i<hex.length; i++){
	console.log(hex[i].toString(16));
}
console.log("length: " + hex.length);

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
	var index = 13; The starting index of the Waspmote ID
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
	Little endian
		var value = payload[startByte + 1];
	value <<= 8;
	value |= payload[startByte] & 0x00FF;
	return value;
}
function getFloat(payload, startByte){
	Little endian
		/*var value = (payload[startByte + 3] << 24) && 0xFF000000;
		  value |= (payload[startByte + 2] << 16) & 0x00FF0000;
		  value |= (payload[startByte + 1] << 8) & 0x0000FF00;
		  value |= payload[startByte] & 0x000000FF;*/
		var negative = (payload[startByte + 3] & 0x80) !== 0; If the msb is set, the number is negative.
		var exponent = payload[startByte + 3] & 0x7F;
	exponent <<= 1;
	exponent |= (0x80 & payload[startByte + 2]) >> 7;
	console.log(exponent);
	var decimal = (0x7F & payload[startByte + 2]) << 8;
	decimal |= payload[startByte + 1];
	decimal <<= 8;
	decimal |= payload[startByte];
	console.log(decimal.toString(16));
	exponent -= 127; Subtract the exponent bias (127) from the excess.
		console.log(exponent);
	var fraction = 1;
	for(var i=0; i < 23; i++){
		fraction += (((((decimal & (1 << (22 - i))) >> (22-i)) & 1) !== 0) ? Math.pow(2, -(i+1)) : 0);
	}
	var value = fraction * Math.pow(2, exponent);
	value = negative ? -value : value;
	return value;
}
var test = [0x00, 0x00, 0x20, 0x40];
console.log("test: " + getFloat(test, 0));
function getFirmwareVersion(payload, startPayloadIndex){
	return getUInt16(payload, startPayloadIndex+1);
}
function getFlags(payload, startPayloadIndex){
	return payload[startPayloadIndex + 4];
}
function getBatteryVoltage(payload, startPayloadIndex){
	return getFloat(payload, startPayloadIndex + 6);
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
console.log(getStartDelimiter(hex));
var startDelim = getStartDelimiter(hex);
var frameType = getFrameType(hex);
var numBytes = getNumberOfBytes(hex);
var sep = getSeparatorCharCode(hex);
var sid = getSerialID(hex);
var wIDEndIndex = getWaspmoteIDEndIndex(hex, sep);
var frameSeq = getFrameSequence(hex, wIDEndIndex);
var sPIdx = getStartPayloadIndex(wIDEndIndex);
var fVer = getFirmwareVersion(hex, sPIdx);
var flags = getFlags(hex, sPIdx);
var battVolt = getBatteryVoltage(hex, sPIdx);
var solar = getSolarChargeCurrent(hex, sPIdx);
var co2 = getCO2(hex, sPIdx);
var temperature = getTemperature(hex, sPIdx);
var humidity = getHumidity(hex, sPIdx);
var pressure = getPressure(hex, sPIdx);
var pm1 = getPM1(hex, sPIdx);
var pm2_5 = getPM2_5(hex, sPIdx);
var pm10 = getPM10(hex, sPIdx);
var no2 = getNO2(hex, sPIdx);
console.log(startDelim);
console.log("frameType: " + frameType);
console.log("numBytes: " + numBytes);
console.log("sep: " + sep);
console.log("sid: " + sid);
console.log("wIDEndIndex: " + wIDEndIndex);
console.log("frameSeq: " + frameSeq);
console.log("sPIdx: " + sPIdx);
console.log("fVer: " + fVer);
console.log("flags: " + flags);
console.log("battVolt: " + battVolt);
console.log("solar: " + solar);
console.log("co2: " + co2);
console.log("temperature: " + temperature);
console.log("humidity: " + humidity);
console.log("pressure: " + pressure);
console.log("pm1: " + pm1);
console.log("pm2_5: " + pm2_5);
console.log("pm10: " + pm10);
console.log("no2: " + no2);
