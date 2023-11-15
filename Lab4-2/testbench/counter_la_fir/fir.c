#include "fir.h"
#include <defs.h>

void __attribute__ ( ( section ( ".mprjram" ) ) ) initfir() {
	//initial your fir
	// {0,-10,-9,23,56,63,56,23,-9,-10,0};
	reg_tap_0 = 0;
	reg_tap_1 = -10;
	reg_tap_2 = -9;
	reg_tap_3 = 23;
	reg_tap_4 = 56;
	reg_tap_5 = 63;
	reg_tap_6 = 56;
	reg_tap_7 = 23;
	reg_tap_8 = -9;
	reg_tap_9 = -10;
	reg_tap_10= 0;

	reg_data_length = 64;

	reg_mprj_datal = 0x00A50000;
	reg_ap_signal = 0x00000001;

}

int* __attribute__ ( ( section ( ".mprjram" ) ) ) fir(){
	initfir();
	//write down your fir

	int s;
	s = reg_ap_signal;
	for (int i = 0; i < 64; i++) {
		while (!((reg_ap_signal >> 4) & 1) && i != 0)
			s = reg_ap_signal;
		reg_x_input = i;

		while (!((reg_ap_signal >> 5) & 1))
			s = reg_ap_signal;
		outputsignal[i] = reg_y_output;
	}

	s = reg_ap_signal;
	reg_mprj_datal = ((0x000000FF & outputsignal[63]) << 24) | 0x005A0000;
	
	return outputsignal;
}
		
