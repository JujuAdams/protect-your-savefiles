var _string  = "Protect Your Savefile\n"
    _string += "@jujuadams 2019/10/01\n\n";
    _string += "saved data  = " + json_encode(save_map) + "\n";
    _string += "loaded data = " + json_encode(load_map) + "\n";
    
draw_text(10, 10, _string);