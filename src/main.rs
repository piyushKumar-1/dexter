use std::process::Command;
use actix_web::{web, App, HttpResponse, HttpServer, Responder};
use tokio::task;

async fn get_resource(params: web::Path<(String, String)>) -> impl Responder {
    let (resource_type, namespace) = params.into_inner();
    let output = task::spawn_blocking(|| {Command::new("kubectl")
               .arg("get")
               .arg(resource_type)
               .arg("-n")
               .arg(namespace)
               .output()
               }).await.expect("failed to execute process");
    if output.is_err() {
        // Handle the error more gracefully
        return HttpResponse::InternalServerError().body("Command execution failed");
    }

    let res = output.unwrap();
    let output_val = String::from_utf8_lossy(&res.stdout);
    let output_err = String::from_utf8_lossy(&res.stderr);
    // Combine stdout and stderr
    let combined_output = output_val.to_string() + &output_err.to_string();
    HttpResponse::Ok().body(combined_output)
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    HttpServer::new(|| {
        App::new()
            .service(
                web::scope("/k8s")
                    .service(
                        web::scope("/get")
                            .route("/{resource_type}/{namespace}", web::get().to(get_resource))
                    )
            )
    })
    .bind("0.0.0.0:8080")?
    .run()
    .await
}
