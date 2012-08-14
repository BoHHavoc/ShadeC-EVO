// Original code by Nils Daumann | www.slindev.com
// http://www.opserver.de/ubb7/ubbthreads.php?ubb=showflat&Number=357697&Main=42496#Post357697

#undef INTERFACE
#define INTERFACE IDirect3DTexture9

DECLARE_INTERFACE_(IDirect3DVolumeTexture9, IDirect3DBaseTexture9)
{
    /*** IUnknown methods ***/
    STDMETHOD(QueryInterface)(THIS_ REFIID riid, void** ppvObj) PURE;
    STDMETHOD_(ULONG,AddRef)(THIS) PURE;
    STDMETHOD_(ULONG,Release)(THIS) PURE;

    /*** IDirect3DBaseTexture9 methods ***/
    STDMETHOD(GetDevice)(THIS_ IDirect3DDevice9** ppDevice) PURE;
    STDMETHOD(SetPrivateData)(THIS_ REFGUID refguid,CONST void* pData,DWORD SizeOfData,DWORD Flags) PURE;
    STDMETHOD(GetPrivateData)(THIS_ REFGUID refguid,void* pData,DWORD* pSizeOfData) PURE;
    STDMETHOD(FreePrivateData)(THIS_ REFGUID refguid) PURE;
    STDMETHOD_(DWORD, SetPriority)(THIS_ DWORD PriorityNew) PURE;
    STDMETHOD_(DWORD, GetPriority)(THIS) PURE;
    STDMETHOD_(void, PreLoad)(THIS) PURE;
    STDMETHOD_(D3DRESOURCETYPE, GetType)(THIS) PURE;
    STDMETHOD_(DWORD, SetLOD)(THIS_ DWORD LODNew) PURE;
    STDMETHOD_(DWORD, GetLOD)(THIS) PURE;
    STDMETHOD_(DWORD, GetLevelCount)(THIS) PURE;
    STDMETHOD(SetAutoGenFilterType)(THIS_ D3DTEXTUREFILTERTYPE FilterType) PURE;
    STDMETHOD_(D3DTEXTUREFILTERTYPE, GetAutoGenFilterType)(THIS) PURE;
    STDMETHOD_(void, GenerateMipSubLevels)(THIS) PURE;
    STDMETHOD(GetLevelDesc)(THIS_ UINT Level,D3DSURFACE_DESC *pDesc) PURE;
    STDMETHOD(GetSurfaceLevel)(THIS_ UINT Level,void** ppSurfaceLevel) PURE;//IDirect3DSurface9
    STDMETHOD(LockRect)(THIS_ UINT Level,D3DLOCKED_RECT* pLockedRect,CONST RECT* pRect,DWORD Flags) PURE;
    STDMETHOD(UnlockRect)(THIS_ UINT Level) PURE;
    STDMETHOD(AddDirtyRect)(THIS_ CONST RECT* pDirtyRect) PURE;
};

MY_DECLARE_INTERFACE(IDirect3DVolumeTexture9)
typedef IDirect3DVolumeTexture9 *LPDIRECT3DVOLUMETEXTURE9;

HRESULT WINAPI
    D3DXCreateVolumeTextureFromFileA(
        LPDIRECT3DDEVICE9         pDevice,
        LPCSTR                    pSrcFile,
        LPDIRECT3DVOLUMETEXTURE9* ppVolumeTexture);

#define D3DXCreateVolumeTextureFromFile D3DXCreateVolumeTextureFromFileA