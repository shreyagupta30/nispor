#![doc = "This file was automatically generated by the varlink rust generator"]
#![allow(non_camel_case_types)]
#![allow(non_snake_case)]
use serde_derive::{Deserialize, Serialize};
use serde_json;
use std::io::BufRead;
use std::sync::{Arc, RwLock};
use varlink::{self, CallTrait};
use nispor::NetState;

#[allow(dead_code)]
#[derive(Clone, PartialEq, Debug)]
pub enum ErrorKind {
    Varlink_Error,
    VarlinkReply_Error,
    InternalError(Option<InternalError_Args>),
}
impl ::std::fmt::Display for ErrorKind {
    fn fmt(&self, f: &mut ::std::fmt::Formatter) -> ::std::fmt::Result {
        match self {
            ErrorKind::Varlink_Error => write!(f, "Varlink Error"),
            ErrorKind::VarlinkReply_Error => write!(f, "Varlink error reply"),
            ErrorKind::InternalError(v) => {
                write!(f, "info.nispor.InternalError: {:#?}", v)
            }
        }
    }
}
pub struct Error(
    pub ErrorKind,
    pub Option<Box<dyn std::error::Error + 'static + Send + Sync>>,
    pub Option<&'static str>,
);
impl Error {
    #[allow(dead_code)]
    pub fn kind(&self) -> &ErrorKind {
        &self.0
    }
}
impl From<ErrorKind> for Error {
    fn from(e: ErrorKind) -> Self {
        Error(e, None, None)
    }
}
impl std::error::Error for Error {
    fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
        self.1
            .as_ref()
            .map(|e| e.as_ref() as &(dyn std::error::Error + 'static))
    }
}
impl std::fmt::Display for Error {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        std::fmt::Display::fmt(&self.0, f)
    }
}
impl std::fmt::Debug for Error {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        use std::error::Error as StdError;
        if let Some(ref o) = self.2 {
            std::fmt::Display::fmt(o, f)?;
        }
        std::fmt::Debug::fmt(&self.0, f)?;
        if let Some(e) = self.source() {
            std::fmt::Display::fmt("\nCaused by:\n", f)?;
            std::fmt::Debug::fmt(&e, f)?;
        }
        Ok(())
    }
}
#[allow(dead_code)]
pub type Result<T> = std::result::Result<T, Error>;
impl From<varlink::Error> for Error {
    fn from(e: varlink::Error) -> Self {
        match e.kind() {
            varlink::ErrorKind::VarlinkErrorReply(r) => Error(
                ErrorKind::from(r),
                Some(Box::from(e)),
                Some(concat!(file!(), ":", line!(), ": ")),
            ),
            _ => Error(
                ErrorKind::Varlink_Error,
                Some(Box::from(e)),
                Some(concat!(file!(), ":", line!(), ": ")),
            ),
        }
    }
}
#[allow(dead_code)]
impl Error {
    pub fn source_varlink_kind(&self) -> Option<&varlink::ErrorKind> {
        use std::error::Error as StdError;
        let mut s: &dyn StdError = self;
        while let Some(c) = s.source() {
            let k = self
                .source()
                .and_then(|e| e.downcast_ref::<varlink::Error>())
                .and_then(|e| Some(e.kind()));
            if k.is_some() {
                return k;
            }
            s = c;
        }
        None
    }
}
impl From<&varlink::Reply> for ErrorKind {
    #[allow(unused_variables)]
    fn from(e: &varlink::Reply) -> Self {
        match e {
            varlink::Reply {
                error: Some(ref t), ..
            } if t == "info.nispor.InternalError" => match e {
                varlink::Reply {
                    parameters: Some(p),
                    ..
                } => match serde_json::from_value(p.clone()) {
                    Ok(v) => ErrorKind::InternalError(v),
                    Err(_) => ErrorKind::InternalError(None),
                },
                _ => ErrorKind::InternalError(None),
            },
            _ => ErrorKind::VarlinkReply_Error,
        }
    }
}
pub trait VarlinkCallError: varlink::CallTrait {
    fn reply_internal_error(&mut self, r#msg: String) -> varlink::Result<()> {
        self.reply_struct(varlink::Reply::error(
            "info.nispor.InternalError",
            Some(
                serde_json::to_value(InternalError_Args { r#msg })
                    .map_err(varlink::map_context!())?,
            ),
        ))
    }
}
impl<'a> VarlinkCallError for varlink::Call<'a> {}
#[derive(Serialize, Deserialize, Debug, PartialEq, Clone)]
pub struct InternalError_Args {
    pub r#msg: String,
}
#[derive(Serialize, Deserialize, Debug, PartialEq, Clone)]
pub struct Get_Reply {
    pub r#net_state: NetState,
}
impl varlink::VarlinkReply for Get_Reply {}
#[derive(Serialize, Deserialize, Debug, PartialEq, Clone)]
pub struct Get_Args {}
pub trait Call_Get: VarlinkCallError {
    fn reply(&mut self, r#net_state: NetState) -> varlink::Result<()> {
        self.reply_struct(Get_Reply { r#net_state }.into())
    }

    // TODO: Need better stuff
    fn fail(&mut self, msg: &str) -> varlink::Result<()> {
        self.reply_struct(varlink::Reply {
            continues: None,
            error: Some(
                format!("info.nispor.InternalError: {}", msg).into(),
            ),
            parameters: None,
        })
    }
}
impl<'a> Call_Get for varlink::Call<'a> {}
pub trait VarlinkInterface {
    fn get(&self, call: &mut dyn Call_Get) -> varlink::Result<()>;
    fn call_upgraded(
        &self,
        _call: &mut varlink::Call,
        _bufreader: &mut dyn BufRead,
    ) -> varlink::Result<Vec<u8>> {
        Ok(Vec::new())
    }
}
pub trait VarlinkClientInterface {
    fn get(&mut self) -> varlink::MethodCall<Get_Args, Get_Reply, Error>;
}
#[allow(dead_code)]
pub struct VarlinkClient {
    connection: Arc<RwLock<varlink::Connection>>,
}
impl VarlinkClient {
    #[allow(dead_code)]
    pub fn new(connection: Arc<RwLock<varlink::Connection>>) -> Self {
        VarlinkClient { connection }
    }
}
impl VarlinkClientInterface for VarlinkClient {
    fn get(&mut self) -> varlink::MethodCall<Get_Args, Get_Reply, Error> {
        varlink::MethodCall::<Get_Args, Get_Reply, Error>::new(
            self.connection.clone(),
            "info.nispor.Get",
            Get_Args {},
        )
    }
}
#[allow(dead_code)]
pub struct VarlinkInterfaceProxy {
    inner: Box<dyn VarlinkInterface + Send + Sync>,
}
#[allow(dead_code)]
pub fn new(
    inner: Box<dyn VarlinkInterface + Send + Sync>,
) -> VarlinkInterfaceProxy {
    VarlinkInterfaceProxy { inner }
}
impl varlink::Interface for VarlinkInterfaceProxy {
    fn get_description(&self) -> &'static str {
        "interface info.nispor\n\ntype IfaceState (\n    name: string,\n    iface_type: string,\n    state: (UP, DOWN, UNKNOWN),\n    mtu: int\n)\n\ntype NetState (\n    iface_states: [string]IfaceState\n)\n\n\nmethod Get() -> (net_state: NetState)\n\nerror InternalError(msg: string)\n"
    }
    fn get_name(&self) -> &'static str {
        "info.nispor"
    }
    fn call_upgraded(
        &self,
        call: &mut varlink::Call,
        bufreader: &mut dyn BufRead,
    ) -> varlink::Result<Vec<u8>> {
        self.inner.call_upgraded(call, bufreader)
    }
    fn call(&self, call: &mut varlink::Call) -> varlink::Result<()> {
        let req = call.request.unwrap();
        match req.method.as_ref() {
            "info.nispor.Get" => {
                self.inner.get(call as &mut dyn Call_Get)
            }
            m => call.reply_method_not_found(String::from(m)),
        }
    }
}