#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <inttypes.h>
#include <linux/i2c-dev.h>
#include <unistd.h>
#include <sys/ioctl.h>

float fetch(int ads_address, const char * dev_name, char * wbuf2, char * wbuf1){
    
    uint8_t write_buf[3];
    uint8_t read_buf[2];

    int i2c_file = open(dev_name, O_RDWR);

    if (i2c_file == -1){
        perror(dev_name);
        exit(1);
    }
    
    if (ioctl(i2c_file, I2C_SLAVE, ads_address) < 0){
        perror("failed to acquire bus access and/or talk to slave");
        exit(1);
    }

    write_buf[0] = 1;
    write_buf[1] = strtol(wbuf1, NULL, 0);
    write_buf[2] = strtol(wbuf2, NULL, 0);

    read_buf[0]= 0;        
    read_buf[1]= 0;
    
    if (write(i2c_file, write_buf, 3) != 3){
        perror("failed to write to the i2c bus");
        exit(1);
    }

    while ((read_buf[0] & 0x80) == 0){
        read(i2c_file, read_buf, 2);
    }

    write_buf[0] = 0;
    write(i2c_file, write_buf, 1);

    read(i2c_file, read_buf, 2);

    int16_t result = read_buf[0] << 8 | read_buf[1];
  
    close(i2c_file);

    return (float)result * 4.096/32767.0;
}

MODULE = RPi::ADC::ADS  PACKAGE = RPi::ADC::ADS

PROTOTYPES: DISABLE

float
fetch (ads_address, dev_name, wbuf2, wbuf1)
    int	ads_address
    const char * dev_name
    char * wbuf2
    char * wbuf1