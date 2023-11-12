#include "fir.h"

void __attribute__ ( ( section ( ".mprjram" ) ) ) initfir() {
	//initial your fir
	reg_tap_1 = 0;
	reg_tap_2 = -10;
	reg_tap_3 = -9;
	reg_tap_4 = 23;
	reg_tap_5 = 56;
	reg_tap_6 = 63;
	reg_tap_7 = 56;
	reg_tap_8 = 23;
	reg_tap_9 = -9;
	reg_tap_10= -10;
	reg_tap_11= 0;
	
	reg_data_length = 64;
}

int* __attribute__ ( ( section ( ".mprjram" ) ) ) fir(){
	initfir();

	reg_mprj_datal = 0x00A50000;
	reg_ap_signal = 0x00000001;

	int data_length = 64;
	//write down your fir
	for (int i=0; i<data_length; i++) {
		// send input signal to fir
		while (reg_ap_signal & 0x00010000 == 0x00010000 )
		reg_x_input = i;
		while (reg_ap_signal & 0x00100000 == 0x00100000 )
		outputsignal[i] = reg_y_output;
		// receive output signal from fir
	}

	reg_mprj_datal = 0x00A50000;
	return outputsignal;
}
		
