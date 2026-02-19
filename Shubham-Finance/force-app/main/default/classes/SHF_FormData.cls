/**
 * @File Name          : SHF_FormData
 * @Description        : Class to format the form data for upload file in Perfios Integration
 * @Author             : Karan Keswani
 * 
 *==============================================================================
 * Ver         Date                     Author                 Modification
 *==============================================================================
 * 1.0                           Initial Version
 */
public class SHF_FormData {
    
    //  The boundary is alligned so it doesn't produce padding characters when base64 encoded.
    private final static string Boundary = '1ff13444ed8140c7a32fc4e6451aa76d';
    
    /**
    *  Returns the request's content type for multipart/form-data requests.
    */
    public static string GetContentType() {
        return 'multipart/form-data; charset="UTF-8"; boundary="' + Boundary + '"';
    }
    
    /**
    *  Pad the value with spaces until the base64 encoding is no longer padded.
    */
    @TestVisible
    private static string SafelyPad(string value,string valueCrLf64,string lineBreaks) {
        string valueCrLf = '';
        blob valueCrLfBlob = null;
        
        while (valueCrLf64.endsWith('=')) {
            value += ' ';
            valueCrLf = value + lineBreaks;
            valueCrLfBlob = blob.valueOf(valueCrLf);
            valueCrLf64 = EncodingUtil.base64Encode(valueCrLfBlob);
        }
        
        return valueCrLf64;
    }
    
    /**
    *  Write a boundary between parameters to the form's body.
    */
    public static string WriteBoundary() {
        string value = '--' + Boundary + '\r\n';
        blob valueBlob = blob.valueOf(value);
        
        return EncodingUtil.base64Encode(valueBlob);
    }
    
    /**
    *  Write a boundary at the end of the form's body.
    */
    public static string WriteBoundary(EndingType ending) {
            string value = '';
            
            if (ending == EndingType.Cr) {
                //  The file's base64 was padded with a single '=',
                //  so it was replaced with '\r'. Now we have to
                //  prepend the boundary with '\n' to complete
                //  the line break.
                value += '\n';
            } else if (ending == EndingType.None) {
                //  The file's base64 was not padded at all,
                //  so we have to prepend the boundary with
                //  '\r\n' to create the line break.
                value += '\r\n';
            }
            //  Else:
            //  The file's base64 was padded with a double '=',
            //  so they were replaced with '\r\n'. We don't have to
            //  do anything to the boundary because there's a complete
            //  line break before it.
            
            value += '--' + Boundary + '--';
            
            blob valueBlob = blob.valueOf(value);
            
            return EncodingUtil.base64Encode(valueBlob);
        }
    /**
    *  Write a key-value pair to the form's body.
    */
    public static string WriteBodyParameter(string key, string value) {
        string contentDisposition = 'Content-Disposition: form-data; name="' + key + '"';
        
        string contentDispositionCrLf = contentDisposition + '\r\n\r\n';
        
        blob contentDispositionCrLfBlob = blob.valueOf(contentDispositionCrLf);
        
        string contentDispositionCrLf64 = EncodingUtil.base64Encode(contentDispositionCrLfBlob);
        
        string content = SafelyPad(contentDisposition, contentDispositionCrLf64, '\r\n\r\n');
        if(key=='file'){
        }
        string valueCrLf = value + '\r\n';
        
        blob valueCrLfBlob = blob.valueOf(valueCrLf);
        if(key=='file'){
        }
        string valueCrLf64 = EncodingUtil.base64Encode(valueCrLfBlob); 
        
        integer file64Length = valueCrLf64 .length();
        String last4Bytes = valueCrLf64 .substring(valueCrLf64 .length()-4,valueCrLf64 .length());        
        
        content += SafelyPad(value, valueCrLf64, '\r\n');
        return content;
    }
    
    /**
    *  Helper enum indicating how a file's base64 padding was replaced.
    */
    public enum EndingType {
          Cr,
            CrLf,
            None
            }
    
    public static string writeFileBody(String key ,Blob attachBody,string filename)
    {
        String header = '--' + boundary + '\r\n' +
            + 'Content-Type: application/octet-stream\r\n'+
            + 'Content-Disposition: form-data; name="'+key+'";filename="' + filename +'"';        
        
        String headerEncoded = EncodingUtil.base64Encode(Blob.valueOf(header + '\r\n\r\n'));
        while(headerEncoded.endsWith('=')){
            header += ' ';
            headerEncoded = EncodingUtil.base64Encode(Blob.valueOf(header+'\r\n\r\n'));
        }
        String footer = '--' + boundary + '--';     
        String bodyEncoded = EncodingUtil.base64Encode(attachBody);
        return headerEncoded+bodyEncoded;
    }   
    
    /**    
    *this method will work for only parameters in the form data    
    */
    public static string append(string key , string value ){
        string formParam=SHF_FormData.WriteBoundary()+WriteBodyParameter(key, value);
        return formParam;
    }
    
    /**    
    *this method will work for file parameters and other params in the form data    
    */
    public static Blob makeBlobWithFile(String key ,Blob attachBody,string filename,string otherParamsEncoded){
        String header = '--' + boundary + '\r\n' +
            + 'Content-Type: application/octet-stream\r\n'+
            + 'Content-Disposition: form-data; name="'+key+'";filename="' + filename +'"';        
        
        String headerEncoded = EncodingUtil.base64Encode(Blob.valueOf(header + '\r\n\r\n'));
        while(headerEncoded.endsWith('=')){
            header += ' ';
            headerEncoded = EncodingUtil.base64Encode(Blob.valueOf(header+'\r\n\r\n'));
        }
        String footer = '--' + boundary + '--';     
        String bodyEncoded = EncodingUtil.base64Encode(attachBody);       
        Blob formBlob = null;    
        String last4Bytes = bodyEncoded .substring(bodyEncoded.length()-4,bodyEncoded.length());
        
        if(last4Bytes.endsWith('==')) {
            last4Bytes = last4Bytes.substring(0,2) + '0K';
            bodyEncoded = bodyEncoded.substring(0,bodyEncoded.length()-4) + last4Bytes;
            String footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));
            formBlob = EncodingUtil.base64Decode(otherParamsEncoded+headerEncoded+bodyEncoded+footerEncoded);
            
        } else if(last4Bytes.endsWith('=')) {
            last4Bytes = last4Bytes.substring(0,3) + 'N';
            bodyEncoded = bodyEncoded.substring(0,bodyEncoded.length()-4) + last4Bytes;
            footer = '\n' + footer;
            String footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));
            formBlob = EncodingUtil.base64Decode(otherParamsEncoded+headerEncoded+bodyEncoded+footerEncoded);
        } else {
            footer = '\r\n' + footer;
            String footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));
            formBlob = EncodingUtil.base64Decode(otherParamsEncoded+headerEncoded+bodyEncoded+footerEncoded);
        }
        
        return formBlob; // returning the form data as a blob 
        
    }
    
    /**    
    *this method will make the blob of the form data if attachments are not required 
    */
    public static Blob makeBlob(string ParamsEncoded){
        
        String footer = '--' + boundary + '--';   
        Blob formBlob = null;    
        
        //footer = '\r\n' + footer;
        String footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));
        formBlob = EncodingUtil.base64Decode(ParamsEncoded+footerEncoded);
        
        return formBlob; // returning the form data as a blob 
        
    }


}