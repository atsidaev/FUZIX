#include <kernel.h>
#include <timer.h>
#include <kdata.h>
#include <printf.h>
#include <devtty.h>


struct blkbuf *bufpool_end = bufpool + NBUFS;

void platform_discard(void)
{
	extern uint8_t discard_size;
	bufptr bp = bufpool_end;

	kprintf("%d buffers reclaimed from discard\n", discard_size);
	
	bufpool_end += discard_size;

	memset( bp, 0, discard_size * sizeof(struct blkbuf) );

	for( bp = bufpool + NBUFS; bp < bufpool_end; ++bp ){
		bp->bf_dev = NO_DEVICE;
		bp->bf_busy = BF_FREE;
	}
}


void platform_idle(void)
{
}

void do_beep(void)
{
}

/* Scan memory return number of 8k pages found */
__attribute__((section(".discard")))
int scanmem(void)
{
	volatile uint8_t *mmu=(uint8_t *)0xffa8;
	volatile uint8_t *ptr=(uint8_t *)0x0100;
	int i;
	for( i = 0; i<256; i+=8 ){
		*mmu=i;
		*ptr=0;
	}
	*mmu=0;
	*ptr=0xff;
	*mmu=8;
	for( i = 8; i<256 && !*ptr ; ){
		i+=8;
		*mmu=i;;
	}
	*mmu=0;
	return i;
}


/*
 Map handling: We have flexible paging. Each map table consists
 of a set of pages with the last page repeated to fill any holes.
 */

void pagemap_init(void)
{
    int i;
    int max = scanmem();
    
    /*  We have 64 8k pages for a CoCo3 so insert every other one
     *  into the kernel allocator map.
     */
    for (i = 10; i < max ; i+=2)
        pagemap_add(i);
    /* add common page last so init gets it */
    pagemap_add(6);
}


void map_init(void)
{
}


uint8_t platform_param(unsigned char *p)
{
	return 0;
}
