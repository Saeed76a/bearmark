#[macro_use]
extern crate rocket;

use bmm::api::fairings::db::Db;
use bmm::api::{bookmark, tag};

use rocket_db_pools::Database;

#[launch]
#[cfg(not(tarpaulin_include))]
async fn rocket() -> _ {
    bmm::utils::logging::setup_console_log();
    bmm::db::connection::run_migrations().await;

    rocket::build()
        .attach(Db::init())
        .mount("/bookmarks", bookmark::routes())
        .mount("/tags", tag::routes())
}
