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
hex = parseHexString("3C3D3E0648330E7863D937420B776D74726F6F6676332D342320");
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
	return payload[5];
}
function getSerialID(payload){
	var start = 6;
	var sid = "";
	for(var i=start; i<start+8; i++){
		sid += payload[i].toString(16);
	}
	return sid;
}
function getWaspmoteIDEndIndex(payload, separatorCode){
	var index = 14; //The starting index of the Waspmote ID
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
	var value = (payload[startByte + 3] << 24) && 0xFF000000;
	value |= (payload[startByte + 2] << 16) & 0x00FF0000;
	value |= (payload[startByte + 1] << 8) & 0x0000FF00;
	value |= payload[startByte] & 0x000000FF;
	var negative = (value & 0x80000000) != 0; //If the msb is set, the number is negative.
	var exponent = (value & 0x7F800000) >> 23;
	var fraction = (value & 0x007FFFFF);
	return value;
}
function getFirmwareVersion(payload, startPayloadIndex){
	return getUInt16(payload, startPayloadIndex+1);
}
function getFlags(payload, startPayloadIndex){
	return payload[startPayloadIndex + 4];
}
console.log(getStartDelimiter(hex));
