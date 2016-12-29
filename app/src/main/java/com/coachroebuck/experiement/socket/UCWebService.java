package com.coachroebuck.experiement.socket;

import android.content.Context;
import android.content.Intent;
import android.os.AsyncTask;
import android.util.Log;

import org.json.JSONObject;

import java.io.BufferedInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.Reader;
import java.io.UnsupportedEncodingException;
import java.lang.ref.WeakReference;
import java.lang.reflect.Type;
import java.net.HttpURLConnection;
import java.net.URL;
import java.security.KeyManagementException;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;

import javax.net.ssl.HostnameVerifier;
import javax.net.ssl.HttpsURLConnection;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLHandshakeException;
import javax.net.ssl.SSLSession;
import javax.net.ssl.X509TrustManager;

/**
 * Created by michaelroebuck on 12/16/16.
 */

public class UCWebService  extends AsyncTask<String, Void, String> {

    protected static String HTTP_METHOD_GET = "GET";
    protected static String HTTP_METHOD_POST = "POST";
    protected static String HTTP_METHOD_PUT = "PUT";
    protected static String HTTP_METHOD_DELETE = "DELETE";

    private final Integer BUFFER_SIZE = 128;
    private WeakReference<UCWebServiceInterface> ucWebServiceInterface = null;
    private String url = null;
    private String httpMethod = null;
    private String apiPostAction = null;
    private String notificationName = null;
    private Context context = null;
    private Class<?> responseClassType;
    private Type responseType;
    private String creationErrorMessage = "";
    private JSONObject postData = null;

    public UCWebService(UCWebServiceInterface webServiceInterface,
                        Context context) {

        setUcWebServiceInterface(webServiceInterface);
        setContext(context);
        setResponseClassType(responseClassType);
        setResponseType(responseType);
    }

    public void stop(Boolean interrupt) {

        sendCancel();
        cancel(interrupt);
    }

    @Override
    protected String doInBackground(String... urls) {

        HttpURLConnection aHttpURLConnection = null;
        String result = "";

        try {

            if (isCancelled()) {
                sendCancel();
            } else if (creationErrorMessage.length() == 0) {
                final URL url = new URL(this.url);

                HostnameVerifier hostnameVerifier = new HostnameVerifier() {
                    @Override
                    public boolean verify(String hostname, SSLSession session) {
                        HostnameVerifier hv =
                                HttpsURLConnection.getDefaultHostnameVerifier();
                        return hv.verify("uchallenge.me", session);
                    }
                };
                HttpsURLConnection.setDefaultHostnameVerifier(new NullHostNameVerifier());
                SSLContext context = SSLContext.getInstance("TLS");
                context.init(null, new X509TrustManager[]{new NullX509TrustManager()}, new SecureRandom());
                HttpsURLConnection.setDefaultSSLSocketFactory(context.getSocketFactory());

                aHttpURLConnection = (HttpURLConnection) url.openConnection();
                aHttpURLConnection.setRequestMethod(httpMethod);
//                aHttpURLConnection.setHostnameVerifier(hostnameVerifier);
                aHttpURLConnection.setRequestProperty("accept", "*/*");
                aHttpURLConnection.setRequestProperty("connection", "close");
                aHttpURLConnection.setRequestProperty("user-agent",
                        "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1)");
                aHttpURLConnection.setDoOutput(true);
                aHttpURLConnection.setDoInput(true);
                aHttpURLConnection.setConnectTimeout(30000);
                aHttpURLConnection.setReadTimeout(30000);
                aHttpURLConnection.setRequestProperty("Content-Type", "application/json; charset=UTF-8");

                System.setProperty("http.keepAlive", "false");

                if (!httpMethod.equalsIgnoreCase(HTTP_METHOD_GET) && getPostData().toString().length() > 0) {
                    OutputStream os = aHttpURLConnection.getOutputStream();
                    os.write(getPostData().toString().getBytes("UTF-8"));
                    os.close();
                }

                InputStream inputStream = new BufferedInputStream(aHttpURLConnection.getInputStream());
//                readStream(in);
//                InputStream inputStream = aHttpURLConnection.getInputStream();
//                BufferedInputStream aBufferedInputStream = new BufferedInputStream(
//                        inputStream);

                //Read the results
                final char[] buffer = new char[BUFFER_SIZE];
                final StringBuilder out = new StringBuilder();
                Reader in = new InputStreamReader(inputStream, "UTF-8");
                Integer rsz = 0;
                do {
                    rsz = in.read(buffer, 0, buffer.length);
                    if (rsz > 0) {
                        out.append(buffer, 0, rsz);
                    }
                } while (rsz > 0);

                in.close();
                result = out.toString();
            }
        } catch (SSLHandshakeException e) {
            e.printStackTrace();
            Log.w(e.getClass().toString(), e.getMessage() + "\nurl=" + this.url);
            sendError(e.getMessage());
        } catch (UnsupportedEncodingException e) {
            e.printStackTrace();
            Log.w(e.getClass().toString(), e.getMessage() + "\nurl=" + this.url);
            sendError(e.getMessage());
        } catch (IOException e) {
            e.printStackTrace();
            Log.w(e.getClass().toString(), e.getMessage() + "\nurl=" + this.url);
            sendError(e.getMessage());
        } //catch (NoSuchAlgorithmException e) {
        catch (NoSuchAlgorithmException e) {
            e.printStackTrace();
            Log.w(e.getClass().toString(), e.getMessage() + "\nurl=" + this.url);
            sendError(e.getMessage());
        } catch (KeyManagementException e) {
            e.printStackTrace();
            Log.w(e.getClass().toString(), e.getMessage() + "\nurl=" + this.url);
            sendError(e.getMessage());
        }
        finally {
            if(aHttpURLConnection != null) {
                aHttpURLConnection.disconnect();
            }
        }
//            e.printStackTrace();
//        } catch (KeyManagementException e) {
//            e.printStackTrace();
//        }

        return result;
    }

    private void sendCancel() {

        if(ucWebServiceInterface != null) {
            ucWebServiceInterface.get().onCancelled();
        }
    }

    private void sendError(String errorMessage) {

        if(ucWebServiceInterface != null) {
            ucWebServiceInterface.get().onError(errorMessage);
        }
    }

    private Boolean sendResponse(String response) {

        Boolean result = true;

        if(ucWebServiceInterface != null) {
            result = ucWebServiceInterface.get().onReceivedList(response);
        }

        return result;
    }

    @Override
    protected void onCancelled() {
        sendCancel();
    }

    public void onDestroy() {

        ucWebServiceInterface = null;
        setUrl(null);
    }

    // onPostExecute displays the results of the AsyncTask.
    @Override
    protected void onPostExecute(String result) {

        super.onPostExecute(result);

        if(creationErrorMessage.length() > 0) {
            sendError(creationErrorMessage);
        }
        else if(isCancelled()) {
            sendCancel();
        }
        else if(!sendResponse(result)) {
            sendError(result);
        }
    }

    protected void setUcWebServiceInterface(UCWebServiceInterface ucWebServiceInterface) {
        if(ucWebServiceInterface != null) {
            this.ucWebServiceInterface = new WeakReference<UCWebServiceInterface>(ucWebServiceInterface);
        }
    }

    protected void setUrl(String url) {
        this.url = url;
    }

    protected Context getContext() {
        return context;
    }

    protected void setContext(Context context) {
        this.context = context;
    }

    public void setHttpMethod(String httpMethod) {
        this.httpMethod = httpMethod;
    }

    public String getCreationErrorMessage() {
        return creationErrorMessage;
    }

    public void setCreationErrorMessage(String creationErrorMessage) {
        this.creationErrorMessage = creationErrorMessage;
    }

    public JSONObject getPostData() {
        return postData;
    }

    public void setPostData(JSONObject postData) {
        this.postData = postData;
    }

    public String getApiPostAction() {
        return apiPostAction;
    }

    public void setApiPostAction(String apiPostAction) {
        this.apiPostAction = apiPostAction;
    }

    public String getNotificationName() {
        return notificationName;
    }

    public void setNotificationName(String notificationName) {
        this.notificationName = notificationName;
    }

    public Class<?> getResponseClassType() {
        return responseClassType;
    }

    public void setResponseClassType(Class<?> responseClassType) {
        this.responseClassType = responseClassType;
    }

    public Type getResponseType() {
        return responseType;
    }

    public void setResponseType(Type responseType) {
        this.responseType = responseType;
    }

    public class NullHostNameVerifier implements HostnameVerifier {

        @Override
        public boolean verify(String hostname, SSLSession session) {
            return true;
        }
    }

    public interface UCWebServiceInterface {
        public Boolean onReceivedList(Object input);
        public void onError(String error);
        public void onCancelled();
    }
}

