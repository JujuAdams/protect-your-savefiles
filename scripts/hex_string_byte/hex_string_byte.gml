/// @param hexString
/// @param byte

var _hex_string = argument0;
var _byte       = argument1;

var _value = 0;

var _high_char = ord(string_char_at(_hex_string, 2*_byte+1));
var _low_char  = ord(string_char_at(_hex_string, 2*_byte+2));

if ((_low_char >= 48) && (_low_char <= 57))
{
    _value += (_low_char - 48);
}
else if ((_low_char >= 97) && (_low_char <= 102))
{
    _value += (_low_char - 87);
}

if ((_high_char >= 48) && (_high_char <= 57))
{
    _value += (_high_char - 48) << 4;
}
else if ((_high_char >= 97) && (_high_char <= 102))
{
    _value += (_high_char - 87) << 4;
}

return _value;

//var _pos = 2*_byte + 1;
//var _hex_reference = "0123456789abcdef";
//return (string_pos(string_char_at(_hex_string, _pos+1), _hex_reference) + (string_pos(string_char_at(_hex_string, _pos), _hex_reference)*16) - 17);