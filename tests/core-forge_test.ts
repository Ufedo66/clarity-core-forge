import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensure can create new app",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const appName = "Test App";
    const version = "1.0.0";
    
    let block = chain.mineBlock([
      Tx.contractCall(
        "core-forge",
        "create-app",
        [types.ascii(appName), types.ascii(version)],
        deployer.address
      )
    ]);
    
    assertEquals(block.receipts[0].result.expectOk(), "u1");
    
    let app = chain.callReadOnlyFn(
      "core-forge",
      "get-app",
      [types.uint(1)],
      deployer.address
    );
    
    app.result.expectSome().expectTuple()["name"].expectAscii(appName);
  }
});

Clarinet.test({
  name: "Ensure only owner can update app version",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const other = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall(
        "core-forge",
        "update-app-version",
        [types.uint(1), types.ascii("2.0.0")],
        other.address
      )
    ]);
    
    block.receipts[0].result.expectErr().expectUint(102);
  }
});

Clarinet.test({
  name: "Ensure can update app status with valid status",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    
    let block = chain.mineBlock([
      Tx.contractCall(
        "core-forge", 
        "update-app-status",
        [types.uint(1), types.ascii("inactive")],
        deployer.address
      )
    ]);

    block.receipts[0].result.expectOk().expectBool(true);
    
    let app = chain.callReadOnlyFn(
      "core-forge",
      "get-app",
      [types.uint(1)],
      deployer.address
    );
    
    app.result.expectSome().expectTuple()["status"].expectAscii("inactive");
  }
});
