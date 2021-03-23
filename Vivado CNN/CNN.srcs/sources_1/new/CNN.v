`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company: IIT Gandhinagar
// Engineer: Team CONVOS
// 
// Create Date: 16.11.2019 06:00:00
// Design Name: CNN module for detection of 1 object from 10 objects 
// 				with 1 filter, no hidden layer, 1 output layer, filter size 3X3, max_pooling filter size 2X2  
// Module Name: CNN
// Project Name: CNN
// Target Devices: FPGA Basys-3 
// Tool Versions: Final Version
// Description: Provided BRAMs as mentioned
// 
// Dependencies: needed BRAM support of 18KB
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:	
// 
//////////////////////////////////////////////////////////////////////////////////

module CNN( output reg [9:0]A, input wire clk);
	parameter I = 8-1, S = 16-1, R = 32, C = 32, R_M = 30, C_M = 30, obj = 10;				// Row and Colums sizes for image and conv_output
	integer flag_data_read = 1, flag_conv = 0, flag_max = 0, flag_final = 0, flag_prob = 0;	// Flags defined for invoking "always" blocks in sequence
	integer i, j, k, r = 0, it = 0, max, t = 0;
	
	integer max_value = 2500, th = 200, alpha = 1;	// ReLu function parameters
	
	integer count = 0;
	integer image_count=-2;
	integer weights_count=-2;
	integer bias_count=-2;
	integer filter_count=-2;

	
	reg signed [I:0]	Image[0:R*C-1];			// Storing cifar-10 data set imgaes for 32X32
	reg signed [S:0] 	Filters[0:obj-1];		// Storing 10 values in filters with *100
	reg signed [S:0] 	Conv[0:R_M*C_M-1];		// Convolution matrix of 30X30
	reg signed [S:0] 	MP[0:((R_M*C_M)/4)-1];	// Max Pooling matix of  15X15
	reg signed [S:0] 	Weights[0:((R_M*C_M)/4)*obj-1]; //225X10 values *1000
	reg signed [S:0] 	Bias[0:obj-1];			// Bias values 1X10, need to be added at output layer *10^5
	reg signed [S:0] 	Final[0:obj-1];			// Final Feauture Calculation
	reg signed [S:0] 	sum = 0, temp = 0;		// storing temporary sum and max values
	
	reg signed [S:0] 	K1, K2, K3;				// Filter constants
	reg signed [S:0] 	K4, K5, K6; 			// Filter constants
	reg signed [S:0] 	K7, K8, K9; 			// Filter constants
	reg signed [S:0]    fb;						// Filter Bias

    wire in_when_writing=0;
    wire wea = 0;

    wire[I:0]	image_value;
    wire[S:0] 	bias;
    wire[S:0] 	filters;
    wire[S:0] 	weights;
    
    reg[31:0]	address_image = 0;
    reg[31:0]	address_weight = 0;
    reg[31:0]	address_bias = 0;
    reg[31:0]	address_filter = 0;

	blk_mem_gen_0 inst0( .wea(wea), .clka(clk), .addra(address_image), .dina(in_when_writing), .douta(image_value) );
	blk_mem_gen_1 inst1( .wea(wea), .clka(clk), .addra(address_weight), .dina(in_when_writing), .douta(weights) );
	blk_mem_gen_2 inst2( .wea(wea), .clka(clk), .addra(address_bias), .dina(in_when_writing), .douta(bias) );
	blk_mem_gen_3 inst3( .wea(wea), .clka(clk), .addra(address_filter), .dina(in_when_writing), .douta(filters) );
	
	always@(posedge clk)	// Initializing parameter loading from BRAM
	if(flag_data_read)
	begin
		// We are skipping 2 clock edges beacause of 2 clock cycle latency in reading Block RAM
		// Image Read
		if (count<1026)		// counting only 1026-2 values 
		begin
			if (image_count > -1)
			begin
				Image[image_count] =  image_value;	// Reading start from 0 index
			end
			else begin end
		
			if(address_image <1024)
				address_image = address_image + 1;
			else
				address_image = 0;
			//$display("Image Array -> %d , %d", address_image ,image_value);    
		end
		else begin end
		
		// Weights
		if (count<2252)		// counting only 2252-2 values 
		begin
			if (weights_count > -1)
			begin
				Weights[weights_count] =  weights;
			end
			else begin end

			if(address_weight <2250)
				address_weight = address_weight + 1;
			else
				address_weight = 0;
			
				//$display("Image Array -> %d , %d", address_image ,weights);    
		end
		else begin end
		 
		 //Bias  
		if (count<12)		// counting only 10-2 values 
		begin
			if (bias_count > -1)
			begin
				Bias[bias_count] =  bias;
			end
			else begin end
			if(address_bias <10)
				address_bias = address_bias + 1;
			else
				begin 
				address_bias = 0;
				end
				//$display("Image Array -> %d , %d", address_bias ,bias);    
		end 
		else begin end
			
		//Filters
		if (count<12)		// counting only 10-2 values 
		begin
			if (filter_count > -1)
				Filters[filter_count] =  filters;	
			else begin end
			
			if(address_filter <10)
				address_filter = address_filter + 1;
			else
				address_filter = 0;
			//$display("Image Array -> %d , %d", address_filter ,image_value);    
		end 
		else begin end     			
		
		// Updating of loading parameters for next posedge 
		if (count<2253)		// updating count variable 
		begin
			count = count + 1;
			image_count = image_count + 1;
			filter_count = filter_count +1;
			bias_count = bias_count +1;
			weights_count = weights_count +1;
		end
		else begin end
		if(count == 2253) 
			begin  
				flag_data_read = 0; 
				flag_conv = 1; 
				count = count+100; 
			end	// Stopping this always block as all reading parameters is done
		else begin end
	end	// Loading data from BRAM completed.

	always@(posedge clk)	// Initializing Convolution on the image
	if(flag_conv)
	begin
		if(it == 0)
		begin  
			r = 0;
			i = 0; j = C; k = 2*C;
			K1 = Filters[0]; K2 = Filters[1]; K3 = Filters[2];	//	First row
			K4 = Filters[3]; K5 = Filters[4]; K6 = Filters[5]; 	//	Second row
			K7 = Filters[6]; K8 = Filters[7]; K9 = Filters[8]; 	//	Third row
			fb = Filters[9];									// 	Filter Bias
			
			Conv[it] = K1*Image[i] + K2*Image[i+1] + K3*Image[i+2] + K4*Image[j] + K5*Image[j+1] + K6*Image[j+2] + K7*Image[k] + K8*Image[k+1] + K9*Image[k+2] + fb;	// Convolution with bias addition			
			
			if(Conv[it] >= max_value) 	Conv[it] = max_value;			//}
			else if( Conv[it] <th ) 	Conv[it] = alpha*(Conv[it]-th);	//} Appling ReLu

			it = it+1; i = i+1; j = j+1; k = k+1;	// Updation of iterators
		end
		else if( it == 900 ) begin flag_conv = 0; flag_max = 1; it = 0; end
		else 
		begin
			if( i > (r+1)*C-3 ) begin r = r+1; i = r*C; j = (r+1)*C; k = (r+2)*C; end

			Conv[it] = K1*Image[i] + K2*Image[i+1] + K3*Image[i+2] + K4*Image[j] + K5*Image[j+1] + K6*Image[j+2] + K7*Image[k] + K8*Image[k+1] + K9*Image[k+2] + fb;	// Convolution with bias addition		
			
			if(Conv[it] >= max_value) 	Conv[it] = max_value;			//}
			else if( Conv[it] <th ) 	Conv[it] = alpha*(Conv[it]-th);	//} Appling ReLu
			
			it = it+1; i = i+1; j = j+1; k = k+1;	// Updation of iterators
		end		
	end	// Convolution completed.
	
	always@(posedge clk)	// Initializing Max Pooling only if flag_max == 1
    if(flag_max)
    begin
        if(!it)
        begin 
            r = 0; i = 0; j = R_M; 
            
            temp = Conv[i];
            if( Conv[i+1] > temp ) temp = Conv[i+1];
            if( Conv[j] > temp ) temp = Conv[j];
            if( Conv[j+1] > temp ) temp = Conv[j+1];
            MP[it] =  temp;
			
            it = it+1;

        end
        else if( it == 225 )begin flag_max = 0; flag_final = 1; sum = 0; j = 0; t = 0; end
        else
        begin
            if( i > (r+1)*C_M-2 )begin r = r+1; i = r*R_M; j = (r+1)*R_M; end
            
            temp = Conv[i];
            if( Conv[i+1] > temp ) temp = Conv[i+1];
            if( Conv[j] > temp ) temp = Conv[j];
            MP[it] =  temp;
            if( Conv[j+1] > temp ) temp = Conv[j+1];
            
			it = it+1; i = i+2; j = j+2;	
        end
    end	// Max Pooling completed.
      
    always@(posedge clk)	// Initializing Calculation of final features only if flag_final == 1
    if(flag_final)
    begin
        if(t == 10) begin flag_final = 0; flag_prob = 1; end
        else if(j == 225)
        begin
            Final[t] = sum + Bias[t];	//	Adding Bias into the matrix product
            sum = 0; j = 0; t=t+1;		// 	resetting the iterators
        end
        else
        begin
            if(j)sum = sum + (MP[j]*Weights[225*t+j]);
            else sum = MP[0]*Weights[225*t];
            
            j = j+1;
        end
    end	// Calculation Probability generating features completed.
    
    always@(posedge clk)	// FPGA Basys-3 Board output generation initialization only if flag_prob == 1
    if(flag_prob)
    begin
        max = 0;
        if(Final[1]>Final[max]) max = 1;	// }
        if(Final[2]>Final[max]) max = 2;	// }
        if(Final[3]>Final[max]) max = 3;	// }
        if(Final[4]>Final[max]) max = 4;	// }
        if(Final[5]>Final[max]) max = 5;	// }	finding the maxima among feautures
        if(Final[6]>Final[max]) max = 6;	// }
        if(Final[7]>Final[max]) max = 7;	// }
        if(Final[8]>Final[max]) max = 8;	// }
        if(Final[9]>Final[max]) max = 9;	// }
        
        A = 0; A[max] = 1;		// Setting the detected bit, turning off other bits
		flag_prob = 0;			// Turning off all processes
    end	// FPGA Basys-3 Board output sending completed.
	
endmodule



// Special Methods for converting your C or C++ for-loops into efficient always blocks chaining 
//
// *********************************************************
// How to convert a for loop into verilog always block
// for(int i = 0; i<n; i++)	// taken from C or C++
// {
//		operations and functions
// }
// 
// Same process implementing using always block using a flag
// integer i = 0, flag = 0;
// ...code
// { flag = 1; }	// when required
// always@(posedge clock)
// if(flag)
// begin
// 		if(i==n) flag = 0;
// 		else
//		begin
//			operations and functions
//			i = i+1;
//		end
// end

//**********************************************************
// How to convert Nested for-looping into verilog always block
// for(int i = 0; i<m; i++)	// in C or C++
// {
// 		for(int j = 0; j<n; j++)
// 		{
// 			operations and functions;
// 		}
// }
//
// Same process implementing using always block using a flag
// integer i, j, flag;
// { flag = 1; }	// when required
// always@(posedge clock)
// if(flag)
// begin
//  if(i == 0 && j == 0)
// 	begin
//  	Outer Loop initialization statements
// 		operations and functions;
// 	end
// 	else if( i == m )
// 	begin
// 		flag = 0;	// process completed
// 	end
// 	else if( j == n )
// 	begin 
// 		j = 0;	// intitialization statements analogous to inner for-loop 
// 		i = i+1; // updation statement of outer for loop
// 		operations and functions;
// 	end
// 	else
// 	begin
// 		operations and functions;
// 		j = j+1;
// 	end
// end