## Tiedostolistaus index

Liitettynä on index.html joka tarvitsee laittaa bucketin juureen ja kertoa että siitä tehdään bucketin website.
Muistakaa muuttaa index.html tiedostossa html title omaksenne ja sitten BUCKET_URL omaksenne. Löytyvät tiedoston alkupuolelta

```s3cmd ws-create --ws-index=index.html s3.//example-bucket```

## CORS kuka tahansa lukee

tiedosto cors.file

ja tuossa on malli miltä näyttää sen jälkeen 

```
s3://field-observatory/ (bucket):
   Location:  us-east-1
   Payer:     BucketOwner
   Ownership: none
   Versioning:none
   Expiration rule: none
   Block Public Access: none
   Policy:    none
   CORS:      <CORSConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/"><CORSRule><ID>FO</ID><AllowedMethod>GET</AllowedMethod><AllowedOrigin>*</AllowedOrigin><AllowedHeader>*</AllowedHeader></CORSRule></CORSConfiguration>
   ACL:       *anon*: READ
   ACL:       field_observatory: FULL_CONTROL
   URL:       http://field-observatory.data.lit.fmi.fi/
```


