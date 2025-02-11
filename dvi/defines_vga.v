// `define VGA_480_272_60FPS
`define VGA_640_480_60FPS

`define RED         24'hff0000
`define GREEN       24'h00ff00
`define BLUE        24'H0000ff


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