GameGlobal.configureGodotWXGameKit = function configureGodotWXGameKit() {
  if (GameGlobal.__godotAdapterConfigured) {
    return;
  }
  GameGlobal.__godotAdapterConfigured = true;
  const module = WXGameKit.gameInstance.Module;
  if (typeof WebAssembly.RuntimeError !== "function") {
    Object.defineProperty(WebAssembly, "RuntimeError", {
      configurable: true,
      value: Error
    });
  }
  const removedModuleKeys = [
    "memoryInitializerPrefixURL",
    "pthreadMainPrefixURL",
    "cdInitializerPrefixURL",
    "filePackagePrefixURL",
    "read",
    "setWindowTitle",
    "TOTAL_MEMORY",
    "ENVIRONMENT",
    "STACK_SIZE",
    "wasmMemory",
    "INITIAL_MEMORY"
  ];
  for (const key of removedModuleKeys) {
    try {
      delete module[key];
    } catch (_) {
      Object.defineProperty(module, key, { configurable: true, value: undefined });
    }
  }
  const optionalValues = {
    noExitRuntime: false,
    preloadPlugins: [],
    print: console.log.bind(console),
    printErr: console.error.bind(console),
    wasmBinary: undefined,
    arguments: ["--main-pack", "index.pck"],
    thisProgram: "./index"
  };
  for (const [key, value] of Object.entries(optionalValues)) {
    const descriptor = Object.getOwnPropertyDescriptor(module, key);
    if (descriptor && (descriptor.get || descriptor.set)) {
      delete module[key];
    }
    Object.defineProperty(module, key, {
      configurable: true,
      enumerable: true,
      writable: true,
      value
    });
  }
  Object.assign(WXGameKit.gameInstance, {
    isDevelopmentBuild: false,
    isProfilingBuild: false,
    ttlAssetBundle: 5,
    enableProfileStats: false,
    iOSAutoGCInterval: 10000,
    textureParallelBundle: false,
    textureBundles: "",
    enableWebSocketDebugLog: false,
    enableSocketDebugLog: false,
    enableWXMGFSWarnLog: true,
    mainLoopMinDelay: 0,
    forceReleaseCacheOnTimeout: false
  });
  console.log("[GODOT WXGAMEKIT] adapter configured for packaged index.pck");
};
