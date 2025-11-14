# TRDP XML Test API Reference

This guide centralizes the TRDP APIs that the XML-driven PD/MD test programs rely on. Each entry lists the official signature (from the public headers) and explains how the test harnesses apply the call so that you can reuse the same pattern in your own tooling.

## XML document and configuration helpers (`tau_xml.h`)

### `tau_prepareXmlDoc`
```c
TRDP_ERR_T tau_prepareXmlDoc(const CHAR8 *pFileName, TRDP_XML_DOC_HANDLE_T *pDocHnd);
```
Loads an XML device description into a DOM tree and returns a document handle. Both `trdp-xmlpd-test` variants call it before reading any configuration so the rest of the pipeline has a parsed document to work with.【F:trdp/src/api/tau_xml.h†L262-L305】【F:trdp/test/xml/trdp-xmlpd-test.c†L1133-L1187】【F:trdp/test/xml/trdp-xmlpd-test-fast.c†L1212-L1252】

### `tau_readXmlDeviceConfig`
```c
TRDP_ERR_T tau_readXmlDeviceConfig(const TRDP_XML_DOC_HANDLE_T *pDocHnd,
                                   TRDP_MEM_CONFIG_T *pMemConfig,
                                   TRDP_DBG_CONFIG_T *pDbgConfig,
                                   UINT32 *pNumComPar, TRDP_COM_PAR_T **ppComPar,
                                   UINT32 *pNumIfConfig, TRDP_IF_CONFIG_T **ppIfConfig);
```
Parses the `<device-configuration>` section to obtain memory pools, debug options, COM parameter tables, and per-interface defaults. The PD tests immediately feed the parsed structures to `tlc_init` and later to session creation.【F:trdp/src/api/tau_xml.h†L308-L333】【F:trdp/test/xml/trdp-xmlpd-test.c†L1177-L1205】【F:trdp/test/xml/trdp-xmlpd-test-fast.c†L1242-L1270】

### `tau_readXmlDatasetConfig`
```c
TRDP_ERR_T tau_readXmlDatasetConfig(const TRDP_XML_DOC_HANDLE_T *pDocHnd,
                                    UINT32 *pNumComId, TRDP_COMID_DSID_MAP_T **ppComIdDsIdMap,
                                    UINT32 *pNumDataset, papTRDP_DATASET_T papDataset);
```
Extracts dataset definitions and the ComID↔Dataset mapping so marshalling knows how to lay out payloads. `trdp-xmlpd-test` calls it in `initMarshalling`, then keeps the returned arrays for filling telegram buffers.【F:trdp/src/api/tau_xml.h†L361-L383】【F:trdp/test/xml/trdp-xmlpd-test.c†L562-L590】

### `tau_readXmlInterfaceConfig`
```c
TRDP_ERR_T tau_readXmlInterfaceConfig(const TRDP_XML_DOC_HANDLE_T *pDocHnd,
                                      const CHAR8 *pIfName,
                                      TRDP_PROCESS_CONFIG_T *pProcessConfig,
                                      TRDP_PD_CONFIG_T *pPdConfig,
                                      TRDP_MD_CONFIG_T *pMdConfig,
                                      UINT32 *pNumExchgPar, TRDP_EXCHG_PAR_T **ppExchgPar);
```
Reads the interface-specific `<telegram>` list along with the PD/MD defaults to be applied to one TRDP session. Each session configuration loop loads the telegram array with this API before calling publish/subscribe helpers.【F:trdp/src/api/tau_xml.h†L335-L359】【F:trdp/test/xml/trdp-xmlpd-test.c†L934-L992】【F:trdp/test/xml/trdp-xmlpd-test-fast.c†L941-L999】

### `tau_freeTelegrams`
```c
void tau_freeTelegrams(UINT32 numExchgPar, TRDP_EXCHG_PAR_T *pExchgPar);
```
Frees the telegram array allocated by `tau_readXmlInterfaceConfig` once the test harness has converted the entries into live publishers/subscribers.【F:trdp/src/api/tau_xml.h†L385-L413】【F:trdp/test/xml/trdp-xmlpd-test.c†L985-L992】【F:trdp/test/xml/trdp-xmlpd-test-fast.c†L989-L999】

### `tau_freeXmlDoc`
```c
void tau_freeXmlDoc(TRDP_XML_DOC_HANDLE_T *pDocHnd);
```
Destroys the DOM handle created by `tau_prepareXmlDoc`. The “fast” PD test and the XML printer reclaim the parsed document once they no longer need to read more structures.【F:trdp/src/api/tau_xml.h†L296-L305】【F:trdp/test/xml/trdp-xmlpd-test-fast.c†L1282-L1301】【F:trdp/test/xml/trdp-xmlprint-test.c†L421-L455】

## Marshalling helpers (`tau_marshall.h`)

### `tau_initMarshall`
```c
TRDP_ERR_T tau_initMarshall(void **ppRefCon,
                            UINT32 numComId, TRDP_COMID_DSID_MAP_T *pComIdDsIdMap,
                            UINT32 numDataSet, TRDP_DATASET_T *pDataset[]);
```
Initializes the marshalling context using the datasets read from XML. The PD tests store the returned reference in `TRDP_MARSHALL_CONFIG_T.pRefCon` and reuse it for every telegram send/receive.【F:trdp/src/api/tau_marshall.h†L80-L86】【F:trdp/test/xml/trdp-xmlpd-test.c†L566-L590】

### `tau_marshall` and `tau_unmarshall`
```c
TRDP_ERR_T tau_marshall(void *pRefCon, UINT32 comId,
                        const UINT8 *pSrc, UINT32 srcSize,
                        UINT8 *pDest, UINT32 *pDestSize,
                        TRDP_DATASET_T **ppDSPointer);
TRDP_ERR_T tau_unmarshall(void *pRefCon, UINT32 comId,
                          UINT8 *pSrc, UINT32 srcSize,
                          UINT8 *pDest, UINT32 *pDestSize,
                          TRDP_DATASET_T **ppDSPointer);
```
Function pointers passed in the `TRDP_MARSHALL_CONFIG_T` so that the stack knows how to serialize/deserialize PD payloads that match the XML dataset catalogue. `trdp-xmlpd-test` stores these callbacks right after `tau_initMarshall` succeeds.【F:trdp/src/api/tau_marshall.h†L89-L176】【F:trdp/test/xml/trdp-xmlpd-test.c†L577-L586】

## Session lifecycle APIs (`trdp_if_light.h`)

### `tlc_init`
```c
TRDP_ERR_T tlc_init(TRDP_PRINT_DBG_T pPrintDebugString,
                    void *pRefCon,
                    const TRDP_MEM_CONFIG_T *pMemConfig);
```
Bootstraps the TRDP stack with the memory pools and optional debug callback found in the XML. Both PD tests call it once the device-level configuration is parsed.【F:trdp/src/api/trdp_if_light.h†L73-L76】【F:trdp/test/xml/trdp-xmlpd-test.c†L1199-L1205】【F:trdp/test/xml/trdp-xmlpd-test-fast.c†L1254-L1274】

### `tlc_openSession`
```c
TRDP_ERR_T tlc_openSession(TRDP_APP_SESSION_T *pAppHandle,
                           TRDP_IP_ADDR_T ownIpAddr,
                           TRDP_IP_ADDR_T leaderIpAddr,
                           const TRDP_MARSHALL_CONFIG_T *pMarshall,
                           const TRDP_PD_CONFIG_T *pPdDefault,
                           const TRDP_MD_CONFIG_T *pMdDefault,
                           const TRDP_PROCESS_CONFIG_T *pProcessConfig);
```
Creates one TRDP session per `<bus-interface>`, using the XML defaults and the marshalling configuration assembled earlier. Each session handle is then used to publish and subscribe telegrams for that interface.【F:trdp/src/api/trdp_if_light.h†L78-L86】【F:trdp/test/xml/trdp-xmlpd-test.c†L934-L993】【F:trdp/test/xml/trdp-xmlpd-test-fast.c†L941-L999】

### `tlc_updateSession`
```c
TRDP_ERR_T tlc_updateSession(TRDP_APP_SESSION_T appHandle);
```
In the “fast” test this call finalizes a session’s run-time tables after all telegrams have been created, ensuring the asynchronous sender/receiver threads see the latest configuration.【F:trdp/src/api/trdp_if_light.h†L97-L99】【F:trdp/test/xml/trdp-xmlpd-test-fast.c†L941-L999】

### `tlc_process`
```c
TRDP_ERR_T tlc_process(TRDP_APP_SESSION_T appHandle,
                       TRDP_FDS_T *pRfds,
                       INT32 *pCount);
```
Runs the single-threaded processing loop for one session. The reference PD test calls it for every configured interface to keep publisher/subscriber state machines moving when no dedicated threads are used.【F:trdp/src/api/trdp_if_light.h†L123-L133】【F:trdp/test/xml/trdp-xmlpd-test.c†L1040-L1092】

### `tlc_closeSession` and `tlc_terminate`
```c
TRDP_ERR_T tlc_closeSession(TRDP_APP_SESSION_T appHandle);
TRDP_ERR_T tlc_terminate(void);
```
Gracefully tears down each session and finally shuts down the library. Both test variants close publishers/subscribers first, then iterate over sessions and terminate TRDP before exiting.【F:trdp/src/api/trdp_if_light.h†L100-L107】【F:trdp/test/xml/trdp-xmlpd-test.c†L1224-L1239】【F:trdp/test/xml/trdp-xmlpd-test-fast.c†L1282-L1301】

## PD telegram APIs (`trdp_if_light.h`)

### `tlp_publish`
```c
TRDP_ERR_T tlp_publish(TRDP_APP_SESSION_T appHandle,
                       TRDP_PUB_T *pPubHandle,
                       void *pUserRef,
                       TRDP_PD_CALLBACK_T pfCbFunction,
                       UINT32 serviceId,
                       UINT32 comId,
                       UINT32 etbTopoCnt,
                       UINT32 opTrnTopoCnt,
                       TRDP_IP_ADDR_T srcIpAddr,
                       TRDP_IP_ADDR_T destIpAddr,
                       UINT32 interval,
                       UINT32 redId,
                       TRDP_FLAGS_T pktFlags,
                       const TRDP_SEND_PARAM_T *pSendParam,
                       const UINT8 *pData,
                       UINT32 dataSize);
```
Transforms each `<destination>` entry into a live publisher by binding the COM-ID, dataset buffer, QoS, and multicast/unicast address. The tests stash the returned handle so they can feed data with `tlp_put` later.【F:trdp/src/api/trdp_if_light.h†L151-L168】【F:trdp/test/xml/trdp-xmlpd-test.c†L593-L718】【F:trdp/test/xml/trdp-xmlpd-test-fast.c†L593-L718】

### `tlp_subscribe`
```c
TRDP_ERR_T tlp_subscribe(TRDP_APP_SESSION_T appHandle,
                         TRDP_SUB_T *pSubHandle,
                         void *pUserRef,
                         TRDP_PD_CALLBACK_T pfCbFunction,
                         UINT32 serviceId,
                         UINT32 comId,
                         UINT32 etbTopoCnt,
                         UINT32 opTrnTopoCnt,
                         TRDP_IP_ADDR_T srcIpAddr1,
                         TRDP_IP_ADDR_T srcIpAddr2,
                         TRDP_IP_ADDR_T destIpAddr,
                         TRDP_FLAGS_T pktFlags,
                         const TRDP_COM_PARAM_T *pRecParams,
                         UINT32 timeout,
                         TRDP_TO_BEHAVIOR_T toBehavior);
```
Registers each `<source>` (or sink-only multicast join) so inbound PD frames can be polled via `tlp_get`. The XML tests convert URIs to IP addresses and keep the handles for the receive loop.【F:trdp/src/api/trdp_if_light.h†L235-L250】【F:trdp/test/xml/trdp-xmlpd-test.c†L728-L891】【F:trdp/test/xml/trdp-xmlpd-test-fast.c†L728-L891】

### `tlp_put`
```c
TRDP_ERR_T tlp_put(TRDP_APP_SESSION_T appHandle,
                   TRDP_PUB_T pubHandle,
                   const UINT8 *pData,
                   UINT32 dataSize);
```
Copies the prepared dataset buffer into the TRDP stack so it can be transmitted according to the publisher’s cycle time. Both PD tests update datasets and invoke `tlp_put` for every publisher during each data period.【F:trdp/src/api/trdp_if_light.h†L193-L198】【F:trdp/test/xml/trdp-xmlpd-test.c†L1004-L1072】【F:trdp/test/xml/trdp-xmlpd-test-fast.c†L1104-L1155】

### `tlp_get`
```c
TRDP_ERR_T tlp_get(TRDP_APP_SESSION_T appHandle,
                   TRDP_SUB_T subHandle,
                   TRDP_PD_INFO_T *pPdInfo,
                   UINT8 *pData,
                   UINT32 *pDataSize);
```
Retrieves the latest payload for a subscribed telegram. The tests iterate over every `TRDP_SUB_T` handle once per loop, copying the payload into their dataset buffers before printing the contents.【F:trdp/src/api/trdp_if_light.h†L268-L274】【F:trdp/test/xml/trdp-xmlpd-test.c†L1074-L1113】【F:trdp/test/xml/trdp-xmlpd-test-fast.c†L1157-L1195】

### `tlp_unpublish` and `tlp_unsubscribe`
```c
TRDP_ERR_T tlp_unpublish(TRDP_APP_SESSION_T appHandle, TRDP_PUB_T pubHandle);
TRDP_ERR_T tlp_unsubscribe(TRDP_APP_SESSION_T appHandle, TRDP_SUB_T subHandle);
```
Cleanup helpers that remove PD publishers/subscribers before closing a session. Both tests walk their telegram arrays at shutdown and call the matching unpublish/unsubscribe for every handle.【F:trdp/src/api/trdp_if_light.h†L188-L266】【F:trdp/test/xml/trdp-xmlpd-test.c†L1224-L1237】【F:trdp/test/xml/trdp-xmlpd-test-fast.c†L1282-L1299】

### `tlp_getInterval`, `tlp_processReceive`, and `tlp_processSend`
```c
TRDP_ERR_T tlp_getInterval(TRDP_APP_SESSION_T appHandle,
                           TRDP_TIME_T *pInterval,
                           TRDP_FDS_T *pFileDesc,
                           TRDP_SOCK_T *pNoDesc);
TRDP_ERR_T tlp_processReceive(TRDP_APP_SESSION_T appHandle,
                              TRDP_FDS_T *pRfds,
                              INT32 *pCount);
TRDP_ERR_T tlp_processSend(TRDP_APP_SESSION_T appHandle);
```
The fast PD harness uses these low-level processing calls instead of `tlc_process` so it can drive transmit/receive paths from dedicated threads. `tlp_getInterval` prepares the `select()` timeout, `tlp_processReceive` handles inbound frames once sockets are readable, and `tlp_processSend` runs the cyclic transmit engine.【F:trdp/src/api/trdp_if_light.h†L137-L205】【F:trdp/test/xml/trdp-xmlpd-test-fast.c†L1003-L1087】

By following the same call sequence—prepare the XML document, extract datasets and interface telegrams, initialize marshalling, open sessions, then publish/subscribe/send/receive with the `tlp_*` APIs—you can build additional XML-driven diagnostics without reverse-engineering the test sources.
