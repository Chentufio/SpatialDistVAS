/*Copyright (C) 2015 Vicente Alcantara Santana.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

*/

declare name "Spatial Distortion";
declare author "Vicente Alcantara Santana (Digital Music Production student at ITESM)";
declare copyright "(C) Vicente Alcantara Santana 2015";
declare license "GNU GPL";

import("music.lib");
import("filter.lib");
import ("oscillator.lib");
import ("effect.lib");


dist	= distGroup(vslider("[1]Distortion", 12, 0, 100, 0.1):smooth(0.999));	// distortion parameter
gain	= distGroup(vslider("[0]Gain", 3, -96, 96, 0.001):smooth(0.999));		// output gain (dB)

// the waveshaping function
f(a,x)	= x*(abs(x) + a)/(x*x + (a-1)*abs(x) + 1);

// gain correction factor to compensate for distortion
g(a)	= 1/sqrt(a+1);

//Wah Code of Julius Smith
crybabyEffect(wah) = *(gs(s)) : tf2(1,-1,0,a1s(s),a2s(s))
with { // wah = pedal angle in [0,1]
	s = 0.999; 
	Q  = pow(2.0,(2.0*(1.0-wah)+1.0));
	fr = 450.0*pow(2.0,2.3*wah);
	g  = 0.1*pow(4.0,wah);


	frn = fr/SR; // pole frequency (cycles per sample)
	R = 1 - PI*frn/Q; // pole radius
	theta = 2*PI*frn; // pole angle
	a1 = 0-2.0*R*cos(theta); // biquad coeff
	a2 = R*R;                // biquad coeff

	a1s(s) = a1 :smooth(s); // "dezippering"
	a2s(s) = a2 :smooth(s);
	gs(s) =  g  :smooth(s);

};

//Groups
wahGroup(x)=vgroup("[2]WahWah Fx",x);
panGroup(x) = vgroup("[0]Pan",x);
echoGroup(x) = vgroup("[1]Delay",x);
distGroup(x) = vgroup("[3]Distortion",x);
masterGroup(x) = vgroup("[4]Mix",x);

//Bypass Checkboxes
a = echoGroup(checkbox("[0]Echo Bypass"));
b = wahGroup(checkbox("[0]Wah Bypass"));
c = distGroup(checkbox("[0]Dist Bypass"));
d = distGroup(checkbox("[0]Pan Bypass"));

//Wah Effect Implementation
wahEffect = _:crybabyEffect((wahdpth)*osc(oscilator))
with{
    oscilator = wahGroup(vslider("[1]WahFreq",0,0,25,0.1):smooth(0.999));
    wahdpth = wahGroup(vslider("[2]WahDepth",0,0,1,0.01):smooth(0.999));
	};


//Panning implementation
pan=(1-(depth*osc(freqs)/2+0.5)):smooth(0.999)
    with{
        freqs=panGroup(vslider("[1]Pan Freq",0,0,10,0.01));
        depth=panGroup(vslider("[2]Pan Depth",0,0,1,0.01));
        
    };

//EchoDelay Implementation
echoFunction = _:((+:fdelay(22000,echoDelay))~*(feedback))
with{
    echoDelay= echoGroup(vslider("[1]Time[tooltip: Echo que va desde 0.001 a 1 s] [unit: ms]", 0.05, 0.001, 1, 0.001)*SR:smooth(0.999));
    feedback = echoGroup(vslider("[2]Feedback[tooltip: va de 0 a 0.99]",0,0,0.99,0.01):smooth(0.999));
};

master = masterGroup(hslider("[0]Master Gain [style:knob]",0.5,0,1,0.01));

distr = _,_ <: ((1-pan)*(bypass1(b,wahEffect) : bypass1(c,out) : bypass1(a,echoFunction)), (pan)*(bypass1(b,wahEffect) : bypass1(c,out) : bypass1(a,echoFunction)) : *(wet),*(wet)), *(1-wet), *(1-wet) :> *(master), *(master)
with{
	out(x) = db2linear(gain)*g(dist)*f(db2linear(dist),x);
	wet = masterGroup(hslider("[1]Wet [style:knob]",0,0,1,0.01));
	};






process	= hgroup("Spatial Distortion", distr);




