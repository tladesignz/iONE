//
//  config.h
//  shadowsocks-libev
//
//  Created by Benjamin Erhart on 01.02.18.
//  Copyright © 2018 Guardian Project. All rights reserved.
//

#define HAVE_PCRE_H 1

#define VERSION "3.1.3"

#define LIB_ONLY 1
#define UDPRELAY_LOCAL 1
#define MODULE_LOCAL 1

#define HAS_SYSLOG 1

/* errno for incomplete non-blocking connect(2) */
#define CONNECT_IN_PROGRESS EINPROGRESS

#define TCP_NODELAY    0x01    /* don't delay send to coalesce packets */
#define TCP_KEEPALIVE  0x02    /* send KEEPALIVE probes when idle for pcb->keep_idle milliseconds */
#define TCP_KEEPIDLE   0x03    /* set pcb->keep_idle  - Same as TCP_KEEPALIVE, but use seconds for get/setsockopt */
#define TCP_KEEPINTVL  0x04    /* set pcb->keep_intvl - Use seconds for get/setsockopt */
#define TCP_KEEPCNT    0x05    /* set pcb->keep_cnt   - Use number of probes sent for get/setsockopt */

