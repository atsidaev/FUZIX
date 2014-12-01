#ifndef __DEVFD_DOT_H__
#define __DEVFD_DOT_H__

/* public interface */
int fd_read(uint8_t minor, uint8_t rawflag, uint8_t flag);
int fd_write(uint8_t minor, uint8_t rawflag, uint8_t flag);
int fd_open(uint8_t minor, uint16_t flag);

/* TR-DOS functions and constants */
void trdos_seek(uint16_t track);
void trdos_transfer(uint16_t sector, uint8_t* buf);

#define TRDOS_READ 0
#define TRDOS_WRITE 0x8000

#endif /* __DEVRD_DOT_H__ */

