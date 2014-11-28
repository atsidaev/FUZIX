#include <kernel.h>
#include <kdata.h>
#include <printf.h>
#include <devfd.h>

int fd_open(uint8_t minor, uint16_t flag)
{
    flag;
    if(minor != 0) {
        udata.u_error = ENODEV;
        return -1;
    }
    return 0;
}

void trdos_seek(uint16_t track);
void trdos_read(uint16_t sector, uint8_t* buf);

static int fd_transfer(bool is_read, uint8_t rawflag)
{
	blkno_t block;

	if (rawflag != 0)
		return 0;
	
	block = udata.u_buf->bf_blk<<1;

	if (!is_read)
		kprintf("WRITING!!!!\r\n");

	trdos_seek(block>>4);
	block &= 15;
	trdos_read(block, udata.u_buf->bf_data);
	trdos_read(block+1, udata.u_buf->bf_data+256);

	return 1;
}

int fd_read(uint8_t minor, uint8_t rawflag, uint8_t flag)
{
    flag;minor;
    return fd_transfer(true, rawflag);
}

int fd_write(uint8_t minor, uint8_t rawflag, uint8_t flag)
{
    flag;minor;
    return fd_transfer(false, rawflag);
}

