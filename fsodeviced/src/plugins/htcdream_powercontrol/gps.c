#include <stdio.h>
#include <stdlib.h>
#include <android-rpc/rpc.h>
#include <android-rpc/rpc_router_ioctl.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <pthread.h>

typedef struct registered_server_struct
{
	/* MUST BE AT OFFSET ZERO!  The client code assumes this when it overwrites
	 *        the XDR for server entries which represent a callback client.  Those
	 *               server entries do not have their own XDRs.
	 *
	 **/
	XDR *xdr;
	/* Because the xdr is NULL for callback clients (as opposed to true
	 *        servers), we keep track of the program number and version number in this
	 *               structure as well.
	 *
	 */
	rpcprog_t x_prog; /* program number */
	rpcvers_t x_vers; /* program version */

	int active;
	struct registered_server_struct *next;
	SVCXPRT *xprt;
	__dispatch_fn_t dispatch;
} registered_server;

struct SVCXPRT
{
	fd_set fdset;
	int max_fd;
	pthread_attr_t thread_attr;
	pthread_t  svc_thread;
	pthread_mutexattr_t lock_attr;
	pthread_mutex_t lock;
	registered_server *servers;
	volatile int num_servers;
};

#define SEND_VAL(x) do { \
	val=x;\
	XDR_SEND_UINT32(clnt, &val);\
} while(0);

uint32_t client_IDs[8];//highest known value is 0xb

struct params {
	uint32_t *data;
	int length;
};

bool_t xdr_args(XDR *clnt, struct params *par) {
	int i;
	uint32_t val=0;
	for(i=0;par->length>i;++i)
		SEND_VAL(par->data[i]);
	return 1;
}

bool_t xdr_result_int(XDR *clnt, uint32_t *result) {
	XDR_RECV_UINT32(clnt, result);
	return 1;
}

struct timeval timeout;
int pdsm_client_init(struct CLIENT *clnt, int client) {
	struct params par;
	uint32_t res;
	par.data=malloc(sizeof(int));
	par.length=1;
	par.data[0]=client;
	if(clnt_call(clnt, 0x2, xdr_args, &par, xdr_result_int, &res, timeout)) {
		printf("pdsm_client_init(%x) failed\n", client);
		free(par.data);
		exit(-1);
	}
	free(par.data);
	printf("pdsm_client_init(%x)=%x\n", client, res);
	client_IDs[client]=res;
	return 0;
}

int pdsm_atl_l2_proxy_reg(struct CLIENT *clnt, int val0, int val1, int val2) {
	struct params par;
	uint32_t res;
	par.data=malloc(sizeof(int)*3);
	par.length=3;
	par.data[0]=val0;
	par.data[1]=val1;
	par.data[2]=val2;
	if(clnt_call(clnt, 0x3, xdr_args, &par, xdr_result_int, &res, timeout)) {
		printf("pdsm_atl_l2_proxy_reg(%x, %x, %x) failed\n", par.data[0], par.data[1], par.data[2]);
		free(par.data);
		exit(-1);
	}
	free(par.data);
	printf("pdsm_atl_l2_proxy_reg(%x, %x, %x)=%x\n", par.data[0], par.data[1], par.data[2], res);
	return res;
}

int pdsm_atl_dns_proxy_reg(struct CLIENT *clnt, int val0, int val1) {
	struct params par;
	uint32_t res;
	par.data=malloc(sizeof(int)*2);
	par.length=2;
	par.data[0]=val0;
	par.data[1]=val1;
	if(clnt_call(clnt, 0x6, xdr_args, &par, xdr_result_int, &res, timeout)) {
		printf("pdsm_atl_dns_proxy_reg(%x, %x) failed\n", par.data[0], par.data[1]);
		free(par.data);
		exit(-1);
	}
	free(par.data);
	printf("pdsm_atl_dns_proxy(%x, %x)=%x\n", par.data[0], par.data[1], res);
	return res;
}

int pdsm_client_pd_reg(struct CLIENT *clnt, int client, int val0, int val1, int val2, int val3, int val4) {
	struct params par;
	uint32_t res;
	par.data=malloc(sizeof(int)*6);
	par.length=6;
	par.data[0]=client_IDs[client];
	par.data[1]=val0;
	par.data[2]=val1;
	par.data[3]=val2;
	par.data[4]=val3;
	par.data[5]=val4;
	if(clnt_call(clnt, 0x4, xdr_args, &par, xdr_result_int, &res, timeout)) {
		printf("pdsm_client_pd_reg(%d, %d, %d, %d, %d, %d) failed\n", par.data[0], par.data[1], par.data[2], par.data[3], par.data[4], par.data[5]);
		free(par.data);
		exit(-1);
	}
	free(par.data);
	printf("pdsm_client_pd_reg(%d, %d, %d, %d, %d, %d)=%d\n", par.data[0], par.data[1], par.data[2], par.data[3], par.data[4], par.data[5], res);
	return res;
}

int pdsm_client_pa_reg(struct CLIENT *clnt, int client, int val0, int val1, int val2, int val3, int val4) {
	struct params par;
	uint32_t res;
	par.data=malloc(sizeof(int)*6);
	par.length=6;
	par.data[0]=client_IDs[client];
	par.data[1]=val0;
	par.data[2]=val1;
	par.data[3]=val2;
	par.data[4]=val3;
	par.data[5]=val4;
	if(clnt_call(clnt, 0x5, xdr_args, &par, xdr_result_int, &res, timeout)) {
		printf("pdsm_client_pa_reg(%d, %d, %d, %d, %d, %d) failed\n", par.data[0], par.data[1], par.data[2], par.data[3], par.data[4], par.data[5]);
		free(par.data);
		exit(-1);
	}
	free(par.data);
	printf("pdsm_client_pa_reg(%d, %d, %d, %d, %d, %d)=%d\n", par.data[0], par.data[1], par.data[2], par.data[3], par.data[4], par.data[5], res);
	return res;
}

int pdsm_client_lcs_reg(struct CLIENT *clnt, int client, int val0, int val1, int val2, int val3, int val4) {
	struct params par;
	uint32_t res;
	par.data=malloc(sizeof(int)*6);
	par.length=6;
	par.data[0]=client_IDs[client];
	par.data[1]=val0;
	par.data[2]=val1;
	par.data[3]=val2;
	par.data[4]=val3;
	par.data[5]=val4;
	if(clnt_call(clnt, 0x6, xdr_args, &par, xdr_result_int, &res, timeout)) {
		printf("pdsm_client_lcs_reg(%d, %d, %d, %d, %d, %d) failed\n", par.data[0], par.data[1], par.data[2], par.data[3], par.data[4], par.data[5]);
		free(par.data);
		exit(-1);
	}
	free(par.data);
	printf("pdsm_client_lcs_reg(%d, %d, %d, %d, %d, %d)=%d\n", par.data[0], par.data[1], par.data[2], par.data[3], par.data[4], par.data[5], res);
	return res;
}

int pdsm_client_ext_status_reg(struct CLIENT *clnt, int client, int val0, int val1, int val2, int val3, int val4) {
	struct params par;
	uint32_t res;
	par.data=malloc(sizeof(int)*6);
	par.length=6;
	par.data[0]=client_IDs[client];
	par.data[1]=val0;
	par.data[2]=val1;
	par.data[3]=val2;
	par.data[4]=val3;
	par.data[5]=val4;
	if(clnt_call(clnt, 0x8, xdr_args, &par, xdr_result_int, &res, timeout)) {
		printf("pdsm_client_ext_status_reg(%d, %d, %d, %d, %d, %d) failed\n", par.data[0], par.data[1], par.data[2], par.data[3], par.data[4], par.data[5]);
		free(par.data);
		exit(-1);
	}
	free(par.data);
	printf("pdsm_client_ext_status_reg(%d, %d, %d, %d, %d, %d)=%d\n", par.data[0], par.data[1], par.data[2], par.data[3], par.data[4], par.data[5], res);
	return res;
}

int pdsm_client_xtra_reg(struct CLIENT *clnt, int client, int val0, int val1, int val2, int val3, int val4) {
	struct params par;
	uint32_t res;
	par.data=malloc(sizeof(int)*6);
	par.length=6;
	par.data[0]=client_IDs[client];
	par.data[1]=val0;
	par.data[2]=val1;
	par.data[3]=val2;
	par.data[4]=val3;
	par.data[5]=val4;
	if(clnt_call(clnt, 0x7, xdr_args, &par, xdr_result_int, &res, timeout)) {
		printf("pdsm_client_xtra_reg(%d, %d, %d, %d, %d, %d) failed\n", par.data[0], par.data[1], par.data[2], par.data[3], par.data[4], par.data[5]);
		free(par.data);
		exit(-1);
	}
	free(par.data);
	printf("pdsm_client_xtra_reg(%d, %d, %d, %d, %d, %d)=%d\n", par.data[0], par.data[1], par.data[2], par.data[3], par.data[4], par.data[5], res);
	return res;
}

int pdsm_client_act(struct CLIENT *clnt, int client) {
	struct params par;
	uint32_t res;
	par.data=malloc(sizeof(int));
	par.length=1;
	par.data[0]=client_IDs[client];
	if(clnt_call(clnt, 0x9, xdr_args, &par, xdr_result_int, &res, timeout)) {
		printf("pdsm_client_act(%d) failed\n", par.data[0]);
		free(par.data);
		exit(-1);
	}
	free(par.data);
	printf("pdsm_client_act(%d)=%d\n", par.data[0], res);
	return res;
}

int pdsm_client_unknown(struct CLIENT *clnt, int val0, int client, int val1, int val2, int val3, int val4, int val5, int val6) {
	struct params par;
	uint32_t res;
	par.data=malloc(sizeof(int)*8);
	par.length=8;
	par.data[0]=val0;
	par.data[1]=client_IDs[client];
	par.data[2]=val1;
	par.data[3]=val2;
	par.data[4]=val3;
	par.data[5]=val4;
	par.data[6]=val5;
	par.data[7]=val6;
	if(clnt_call(clnt, 0x1e, xdr_args, &par, xdr_result_int, &res, timeout)) {
		printf("pdsm_client_unknown() failed\n");
		exit(-1);
	}
	printf("pdsm_client_unknown()=%d\n", res);
	return res;
}

int pdsm_get_position(struct CLIENT *clnt, int val0, int val1, int val2, int val3, int val4, int val5, int val6, int val7, int val8, int val9, int val10, int val11, int val12, int val13, int val14, int val15, int val16, int val17, int val18, int val19, int val20, int val21, int val22, int val23, int val24, int val25, int val26, int val27) {
	struct params par;
	uint32_t res;
	par.data=malloc(sizeof(int)*28);
	par.length=28;
	par.data[0]=val0;
	par.data[1]=val1;
	par.data[2]=val2;
	par.data[3]=val3;
	par.data[4]=val4;
	par.data[5]=val5;
	par.data[6]=val6;
	par.data[7]=val7;
	par.data[8]=val8;
	par.data[9]=val9;
	par.data[10]=val10;
	par.data[11]=val11;
	par.data[12]=val12;
	par.data[13]=val13;
	par.data[14]=val14;
	par.data[15]=val15;
	par.data[16]=val16;
	par.data[17]=val17;
	par.data[18]=val18;
	par.data[19]=val19;
	par.data[20]=val20;
	par.data[21]=val21;
	par.data[22]=val22;
	par.data[23]=val23;
	par.data[24]=val24;
	par.data[25]=val25;
	par.data[26]=val26;
	par.data[27]=val27;
	if(clnt_call(clnt, 0xb, xdr_args, &par, xdr_result_int, &res, timeout)) {
		printf("pdsm_client_get_position() failed\n");
		exit(-1);
	}
	printf("pdsm_client_get_position()=%d\n", res);
	return res;
}

void dispatch(struct svc_req* a, registered_server* svc) {
	int i;
	uint32_t *data=svc->xdr->in_msg;
	uint32_t result=0;
	printf("received some kind of event\n");
	for(i=0;i< svc->xdr->in_len/4;++i) {
		printf("%08x ", ntohl(data[i]));
	}
	printf("\n");
	for(i=0;i< svc->xdr->in_len/4;++i) {
		printf("%010d ", ntohl(data[i]));
	}
	printf("\n");
	//ACK
	svc_sendreply(svc, xdr_int, &result);
}

static struct CLIENT* clnt;

void gps_query_setup()
{
	//timeout isn't taken in account by librpc
	struct timeval timeout;
	clnt=clnt_create(NULL, 0x3000005B, 0x90380d3d, NULL);
#if 0
	struct CLIENT *clnt_atl=clnt_create(NULL, 0x3000001D, 0x90380d3d, NULL);
#else
	struct CLIENT *clnt_atl=clnt_create(NULL, 0x3000001D, 0x51c92bd8, NULL);
#endif


	int i;
	SVCXPRT *svc=svcrtr_create();
	xprt_register(svc);
	svc_register(svc, 0x3100005b, 0xb93145f7, dispatch,0);
	svc_register(svc, 0x3100005b, 0, dispatch,0);
	svc_register(svc, 0x3100001d, 0/*xb93145f7*/, dispatch,0);
	if(!clnt) {
		printf("Failed creating client\n");
		return -1;
	}
	if(!svc) {
		printf("Failed creating server\n");
		return -2;
	}

#if 0
	printf("pdsm_client_deact(0xDA3);\n");
	if(clnt_call(clnt, 0x9, xdr_args, 6, xdr_result, 6, timeout)) {
		printf("\tfailed\n");
		return -1;
	}

	printf("pdsm_client_init(2)\n");
	if(clnt_call(clnt, 0x2, xdr_args, 0, xdr_result, 0, timeout)) {
		printf("\tfailed\n");
		return -1;
	}


	printf("pdsm_client_pd_reg(0x%x, 0x00, 0x00, 0x00, 0xF3F0FFFF, -1);\n", client_ID);
	if(clnt_call(clnt, 0x4, xdr_args, 1, xdr_result, 1, timeout)) {
		printf("\tfailed\n");
		return -1;
	}

	printf("pdsm_client_ext_status_reg(0xDA3, 0x00, 0x01, 0x00, 0x04, -1);\n");
	if(clnt_call(clnt, 0x7, xdr_args, 2, xdr_result, 2, timeout)) {
		printf("\tfailed\n");
		return -1;
	}

	printf("pdsm_client_act(0xDA3);\n");
	if(clnt_call(clnt, 0x9, xdr_args, 3, xdr_result, 3, timeout)) {
		printf("\tfailed\n");
		return -1;
	}

	printf("BIG BREATH\n");
	printf("BIGGER BREATH\n");

	/*
	printf("pdsm_client_end_session(0xb, 0x00, 0x00, 0xda3);\n");
	if(clnt_call(clnt, 0xc, xdr_args, 5, xdr_result, 5, timeout)) {
		printf("\tfailed\n");
		return -1;
	}*/
	printf("pdsm_client_get_position(0xda3, 0xb);\n");
	if(clnt_call(clnt, 0xB, xdr_args, 4, xdr_result, 4, timeout)) {
		printf("\tfailed\n");
		return -1;
	}
	sleep(1);
	return 1;

	while(1) {
		/*
		printf("pdsm_client_get_position(0xDA3, 0xa);\n");
		if(clnt_call(clnt, 0xB, xdr_args, 7, xdr_result, 7, timeout)) {
			printf("\tfailed\n");
			return -1;
		}*/
		sleep(1);
	}

	/*
	for(i=0;i<256;++i) {
		printf("clk_regime_sec_msm_get_clk_freq_khz(%d);\n", i);
		if(clnt_call(clnt, 0x24, xdr_args, i, xdr_result, 42, timeout)) {
			printf("\tfailed\n");
			return -1;
		}
	}*/
#endif
#if 0 //Android libgps
	pdsm_client_init(clnt, 0x1);
	pdsm_client_init(clnt, 0xb);
	/*
	pdsm_atl_l2_proxy_reg(clnt_atl, 0x1, 0xa9710411, 0xa97103f1);
	pdsm_atl_l2_proxy_reg(clnt_atl, 0x1, 0xa9710411, 0xa97103f1);*/
	pdsm_client_pd_reg(clnt, 0x1, 0x0049f3a0, 0xa970bf81, 0x0, 0xf310ffff, 0xa970bee1);
	pdsm_client_pa_reg(clnt, 0x1, 0x0049f3a0, 0xa970bf61, 0, 0xfefe0, 0xa970bec1);
	pdsm_client_lcs_reg(clnt, 0x1, 0x0049f3a0, 0xa970bf41, 0x0, 0x3f0, 0xa970bea1);
	pdsm_client_ext_status_reg(clnt, 0x1, 0x0049f3a0, 0xa970bf21, 0x0, 0x7, 0x970be81);
	pdsm_client_xtra_reg(clnt, 0xb, 0x49f3f8, 0xa970bf01, 0x0, 0x03, 0xa970be61);
	pdsm_client_act(clnt, 0x1);
	pdsm_client_act(clnt, 0xb);
	//pdsm_client_unknown(clnt, 0xa970bdc1, 0xb, 1, 0xdc, 0xab598915, 0xcd, 0x1, 0x0);
	pdsm_client_pd_reg(clnt, 0x1, 0x0049f3a0, 0xa970bf81, 0x0, 0xf310ffff, 0xa970bee1);
	pdsm_client_pa_reg(clnt, 0x1, 0x0049f3a0, 0xa970bf61, 0x0, 0x000fefe0, 0xa970bec1);
	pdsm_client_lcs_reg(clnt, 0x1, 0x0049f3a0, 0xa970bf41, 0x0, 0x3f0, 0xa970bea1);
	pdsm_client_ext_status_reg(clnt, 0x1, 0x0049f3a0, 0xa970bf21, 0x0, 0x7, 0xa970be81);
	pdsm_client_xtra_reg(clnt, 0xb, 0x0049f3f8, 0xa970bf01, 0x00, 0x03, 0xa970be61);
	pdsm_client_act(clnt, 0x1);
	pdsm_client_act(clnt, 0xb);
	pdsm_get_position(clnt, 0xa970be41, 0x0049f3a0, 0x00000001, 0x00000001, 0x00000002, 0x0000000a, 0x00000001, 0x00000001, 0x00000000, 0x480eddc0, 0x00006c1c, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000001, 0x00000032, 0x00000078, 0x0000050a);
	while(1) sleep(1);
#endif
#if 1	//Wrapped wince
	pdsm_client_init(clnt, 2);
	pdsm_client_pd_reg(clnt, 2, 0, 0, 0, 0xF3F0FFFF, 0);
	//pdsm_client_pd_reg(clnt, 2, 0, 0, 0, 0xF310FFFF, 0);
	pdsm_client_ext_status_reg(clnt, 2, 0, 0, 0, 0x4, 0);
	pdsm_client_act(clnt, 2);
	pdsm_client_pa_reg(clnt, 2, 0, 2, 0, 0x7ffefe0, 0);
	pdsm_client_init(clnt, 0xb);
	pdsm_client_xtra_reg(clnt, 0xb, 0, 3, 0, 7, 0);
	pdsm_client_act(clnt, 0xb);
	pdsm_atl_l2_proxy_reg(clnt_atl, 1,0,0);
	pdsm_atl_dns_proxy_reg(clnt_atl, 1,0);
	pdsm_client_init(clnt, 4);
	pdsm_client_lcs_reg(clnt, 4, 0,0,0,0x3f0, 0);
	pdsm_client_act(clnt, 4);

	//pdsm_get_position(clnt, 0x0000000B, 0x00000000, 0x00000001, 0x00000001, 0x00000001, 0x3B9AC9FF, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000001, 0x00000032, 0x00000002, client_IDs[1]);
	pdsm_get_position(clnt, 0, 0, 1, 1, 1, 0x3B9AC9FF, 1, 0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0, 0,0,1,32,2,client_IDs[2]);
#endif
}

void gps_query_iteration()
{
	pdsm_get_position(clnt, 0, 0, 1, 1, 1, 0x3B9AC9FF, 1, 0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0, 0,0,1,32,2,client_IDs[2]);
	//	pdsm_get_position(clnt, 0x0000000A, 0x00000000, 0x00000001, 0x00000001, 0x00000001, 0x3B9AC9FF, 0x00000001, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000001, 0x00000032, 0x00000002, 0x00000DA3);
}

void gps_query_shutdown()
{
	// ???
}
