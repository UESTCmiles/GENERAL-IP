// `define VGA_480_272_60FPS
//`define VGA_640_480_60FPS
`define VGA_1024_768_60FPS
//`define VGA_1280_720_30FPS
//`define VGA_1280_720_60FPS
//`define VGA_1920_1080_60FPS

`define RED         24'hff0000
`define GREEN       24'h00ff00
`define BLUE        24'H0000ff

`define POS_POLARITY    1'b1
`define NEG_POLARITY    1'b0


`ifdef VGA_480_272_60FPS
    `define HOR_SYNC    'd41
    `define HOR_BACK    'd2
    `define HOR_ACTIVE  'd480
    `define HOR_FRONT   'd2
    `define HOR_TOTAL   `HOR_SYNC + `HOR_BACK + `HOR_ACTIVE + `HOR_FRONT

    `define VER_SYNC    'd10
    `define VER_BACK    'd2
    `define VER_ACTIVE  'd272
    `define VER_FRONT   'd2
    `define VER_TOTAL   `VER_SYNC + `VER_BACK + `VER_ACTIVE + `VER_FRONT
`endif

`ifdef VGA_640_480_60FPS
    `define POLARITY    1'b0
    
    `define HOR_SYNC    'd96
    `define HOR_BACK    'd48
    `define HOR_ACTIVE  'd640
    `define HOR_FRONT   'd16
    `define HOR_TOTAL   `HOR_SYNC + `HOR_BACK + `HOR_ACTIVE + `HOR_FRONT

    `define VER_SYNC    'd2
    `define VER_BACK    'd33
    `define VER_ACTIVE  'd480
    `define VER_FRONT   'd10
    `define VER_TOTAL   `VER_SYNC + `VER_BACK + `VER_ACTIVE + `VER_FRONT
`endif

`ifdef VGA_1024_768_60FPS
    `define POLARITY    1'b0
    
    `define HOR_SYNC    'd136
    `define HOR_BACK    'd160
    `define HOR_ACTIVE  'd1024
    `define HOR_FRONT   'd24
    `define HOR_TOTAL   `HOR_SYNC + `HOR_BACK + `HOR_ACTIVE + `HOR_FRONT

    `define VER_SYNC    'd6
    `define VER_BACK    'd29
    `define VER_ACTIVE  'd768
    `define VER_FRONT   'd3
    `define VER_TOTAL   `VER_SYNC + `VER_BACK + `VER_ACTIVE + `VER_FRONT
`endif

`ifdef VGA_1280_720_30FPS
    `define POLARITY    1'b0
    
    `define HOR_SYNC    'd40
    `define HOR_BACK    'd220
    `define HOR_ACTIVE  'd1280
    `define HOR_FRONT   'd110
    `define HOR_TOTAL   `HOR_SYNC + `HOR_BACK + `HOR_ACTIVE + `HOR_FRONT

    `define VER_SYNC    'd5
    `define VER_BACK    'd20
    `define VER_ACTIVE  'd720
    `define VER_FRONT   'd5
    `define VER_TOTAL   `VER_SYNC + `VER_BACK + `VER_ACTIVE + `VER_FRONT
`endif

`ifdef VGA_1280_720_60FPS
    `define POLARITY    1'b0
    
    `define HOR_SYNC    'd40
    `define HOR_BACK    'd220
    `define HOR_ACTIVE  'd1280
    `define HOR_FRONT   'd110
    `define HOR_TOTAL   `HOR_SYNC + `HOR_BACK + `HOR_ACTIVE + `HOR_FRONT

    `define VER_SYNC    'd5
    `define VER_BACK    'd20
    `define VER_ACTIVE  'd720
    `define VER_FRONT   'd5
    `define VER_TOTAL   `VER_SYNC + `VER_BACK + `VER_ACTIVE + `VER_FRONT
`endif

`ifdef VGA_1920_1080_60FPS
    `define POLARITY    1'b0

    `define HOR_SYNC    'd44
    `define HOR_BACK    'd148
    `define HOR_ACTIVE  'd1920
    `define HOR_FRONT   'd88
    `define HOR_TOTAL   `HOR_SYNC + `HOR_BACK + `HOR_ACTIVE + `HOR_FRONT

    `define VER_SYNC    'd5
    `define VER_BACK    'd36
    `define VER_ACTIVE  'd1080
    `define VER_FRONT   'd4
    `define VER_TOTAL   `VER_SYNC + `VER_BACK + `VER_ACTIVE + `VER_FRONT
`endif


